"""Derives loader-relative runtime library search paths."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_cc//cc:defs.bzl", "CcInfo")
load("@rules_cc//cc/common:cc_shared_library_info.bzl", "CcSharedLibraryInfo")

# See the doc-string for `derive_runtime_library_search_directories` for a mental
# model of how to read this file.

def _path_segments(path):
    normalized = paths.normalize(path)
    if normalized == ".":
        return []
    return [segment for segment in normalized.split("/") if segment]

# `File.short_path` for external dependencies appears as `../repo/...` because
# it is calculated in runfiles space, where external dependencies are adjacent to
# the main repo:
#
#   app.runfiles/
#     _main/
#       myapp/app
#     zlib/
#       lib/libz.so
#
# From execroot/output coordinates, the same external dependency appears under
# `external/repo/...`:
#
#   <output_base>/execroot/_main/
#     bazel-out/
#       k8-fastbuild/
#         bin/
#           myproj/
#             myapp/app
#           external/
#             zlib/lib/libz.so
#
# The binary inside the runfiles is a symlink to the file in execroot. When
# executing a binary through a symlink the $ORIGIN on in its RUNPATH evaluates
# to the path of the real file. Therefore, for it to find the dependent shared
# libs, we need the path to be in execroot coordinates. On Darwin, @loader_path
# in LC_RPATH behaves the same way. Hence converting `../` to `external/`.
def _runtime_search_path(path):
    segments = _path_segments(path)
    if len(segments) >= 2 and segments[0] == "..":
        return "external/" + "/".join(segments[1:])
    return "/".join(segments)

def _common_prefix_length(left, right):
    max_common_segment_count = len(left)
    if len(right) < max_common_segment_count:
        max_common_segment_count = len(right)

    for index in range(max_common_segment_count):
        if left[index] != right[index]:
            return index

    return max_common_segment_count

# Return the path fragment appended after `$ORIGIN` or `@loader_path`. For
# example, from "pkg/python/bin" to "pkg/python/lib" this returns "../lib".
def _relative_path(from_path, to_path):
    from_segments = _path_segments(_runtime_search_path(from_path))
    to_segments = _path_segments(_runtime_search_path(to_path))
    common_segment_count = _common_prefix_length(from_segments, to_segments)

    # Drop the shared prefix, then walk up from the origin and down to the target.
    relative_segments = (
        [".."] * (len(from_segments) - common_segment_count) +
        to_segments[common_segment_count:]
    )
    return "/".join(relative_segments) if relative_segments else "."

def _dedupe_strings(strings):
    # Preserve first-seen order because runtime search directory order affects
    # which matching soname the dynamic loader resolves first.
    seen = {}
    deduped = []
    for string in strings:
        if string not in seen:
            seen[string] = True
            deduped.append(string)
    return deduped

def _dynamic_libraries(linker_input):
    dynamic_libraries = []
    for library in linker_input.libraries:
        if library.dynamic_library:
            dynamic_libraries.append(library.dynamic_library)
        if library.resolved_symlink_dynamic_library:
            dynamic_libraries.append(library.resolved_symlink_dynamic_library)
    return dynamic_libraries

def _dynamic_libraries_from_dep(dep):
    dynamic_libraries = []
    if CcInfo in dep:
        for linker_input in dep[CcInfo].linking_context.linker_inputs.to_list():
            dynamic_libraries.extend(_dynamic_libraries(linker_input))

    if CcSharedLibraryInfo in dep:
        cc_shared_library_info = dep[CcSharedLibraryInfo]
        dynamic_libraries.extend(_dynamic_libraries(cc_shared_library_info.linker_input))
        for dynamic_dep in cc_shared_library_info.dynamic_deps.to_list():
            dynamic_libraries.extend(_dynamic_libraries(dynamic_dep.linker_input))

    return dynamic_libraries

def _dynamic_library_dirs_from_deps(ctx):
    dynamic_library_dirs = []
    for dep in getattr(ctx.attr, "deps", []) + getattr(ctx.attr, "dynamic_deps", []):
        for dynamic_library in _dynamic_libraries_from_dep(dep):
            dynamic_library_dirs.append(paths.dirname(dynamic_library.short_path))
    return _dedupe_strings(dynamic_library_dirs)

# Declared output files provide the default origins. A binary at
# "pkg/python/bin/python3.10" contributes "pkg/python/bin"; a shared library at
# "pkg/python/lib/libpython.so" contributes "pkg/python/lib".
def _dirs_from_files(files):
    return [
        paths.dirname(file.short_path)
        for file in files
    ]

# Build the install-relative path used when the framework declared an output.
# This is the suffix we expect to strip from the output's `File.short_path`.
def _install_path(dir_, file):
    dir_ = dir_.strip("/")
    return paths.join(dir_, file) if dir_ else file

# Recover the foreign_cc INSTALLDIR in `File.short_path` space. For example,
# "pkg/python/lib/libpython.so" minus "lib/libpython.so" gives "pkg/python".
def _derive_installdir(output_file, install_path):
    install_path = install_path.lstrip("/")
    suffix = "/" + install_path
    short_path = output_file.short_path

    if short_path.endswith(suffix):
        return short_path[:-len(suffix)]

    fail("Output {} does not end with install-relative path {}".format(
        short_path,
        install_path,
    ))

def _installdir_from_outputs(ctx, outputs):
    if outputs.libraries.shared_libraries:
        return _derive_installdir(
            outputs.libraries.shared_libraries[0],
            _install_path(ctx.attr.out_lib_dir, ctx.attr.out_shared_libs[0]),
        )

    if outputs.out_binary_files:
        return _derive_installdir(
            outputs.out_binary_files[0],
            _install_path(ctx.attr.out_bin_dir, ctx.attr.out_binaries[0]),
        )

    if outputs.data_dirs:
        return _derive_installdir(
            outputs.data_dirs[0],
            ctx.attr.out_data_dirs[0].lstrip("/"),
        )

    if outputs.data_files:
        return _derive_installdir(
            outputs.data_files[0],
            ctx.attr.out_data_files[0].lstrip("/"),
        )

    return None

# Users specify extra origins relative to INSTALLDIR, for example
# "lib/python3.10/lib-dynload". Expand those into the same `File.short_path`
# space as declared outputs. I.e. append INSTALLDIR
def _origins_from_install_tree(installdir, install_tree_origins):
    origins = []
    for install_tree_origin in install_tree_origins:
        origin = install_tree_origin.lstrip("/")
        origins.append(paths.join(
            installdir,
            origin,
        ) if origin else installdir)
    return origins

# Return a list of short_path directories of where the rule's outputs (shared
# lib/binaries) may be at runtime. This includes any user defined origins in
# the same format.
#
# Examples:
#   shared lib "pkg/python/lib/libpython.so" contributes "pkg/python/lib"
#   binary "pkg/python/bin/python3.10" contributes "pkg/python/bin"
#   additional origin "lib/python3.10/lib-dynload" under INSTALLDIR
#     "pkg/python" contributes "pkg/python/lib/python3.10/lib-dynload"
#
#   so this returns:
#   [
#       "pkg/python/lib",
#       "pkg/python/bin",
#       "pkg/python/lib/python3.10/lib-dynload",
#   ]
def _evaluate_origins(installdir, output_files, additional_origins):
    return _dedupe_strings(
        _dirs_from_files(output_files) +
        _origins_from_install_tree(
            installdir,
            additional_origins,
        ),
    )

def _search_directories(origins, library_dirs):
    directories = []
    for origin in origins:
        for library_dir in library_dirs:
            directories.append(_relative_path(origin, library_dir))
    return directories

# Return the sibling-solib search entry for a dependent dynamic library dir.
# Bazel often links against solib symlinks instead of real output paths, and a
# sibling entry lets a library loaded from one solib artifact directory find a
# dependency in another.
#
# For example, for a dep_library_dir of:
#   "_solib_k8/_Uthirdparty_Szlib"
#
# This will return the runtime search path of relative to _solib_k8:
#   "../_Uthirdparty_Szlib"
#
# Inputs without a solib root and artifact directory return None:
#   "pkg/zlib/lib" -> None
#   "_solib_k8" -> None
#
# This helper assumes that the path of the library (the ones we are building in
# the rule) needing the solib sibling search directory is exactly 1 directory
# deep under the solib root. e.g.
# "_solib_k8/_Uthirdparty_Szlib/libz.so" or
# "_solib_k8/_Uthirdparty_Sopenssl__Slib/libcrypto.so"
#
# While this is true for most scenarios, edge cases do exist. One example of
# this is to set "dynamic_library_symlink_path" when using
# cc_common.create_library_to_link. However, it is
# not possible to account for this without knowing the solib path of library
# we are building in advance. So this is our best effort.
def _solib_sibling_search_directory(dep_library_dir):
    segments = _path_segments(dep_library_dir)
    if len(segments) < 2 or not segments[0].startswith("_solib_"):
        return None

    artifact_dir_under_solib = "/".join(segments[1:])
    if not artifact_dir_under_solib:
        return None

    return "../" + artifact_dir_under_solib

def _solib_sibling_search_directories(dep_library_dirs):
    directories = []
    for dep_library_dir in dep_library_dirs:
        solib_sibling_directory = _solib_sibling_search_directory(dep_library_dir)
        if solib_sibling_directory:
            directories.append(solib_sibling_directory)
    return directories

# Runtime search directories are derived from the places the rule's outputs may
# be loaded from at runtime.
#
# For each group of output_files, we build a set of origins:
#   1. default origins from declared outputs, such as "pkg/python/bin" or
#      "pkg/python/lib", where "python" is the lib_name.
#   2. user-provided origins under INSTALLDIR, such as
#      "lib/python3.10/lib-dynload"
#
# From each origin, we add relative search paths to:
#   1. the rule's own declared shared-library directories
#   2. dynamic-library directories exposed by deps and dynamic_deps
#
# Those relative paths become entries after `$ORIGIN` on ELF or `@loader_path`
# on Darwin.
def _runtime_library_search_directories_for_outputs(
        output_files,
        additional_origins,
        installdir,
        self_library_dirs,
        dep_library_dirs):
    origins = _evaluate_origins(
        installdir,
        output_files,
        additional_origins,
    )

    directories = []
    directories.extend(_search_directories(origins, self_library_dirs))
    directories.extend(_search_directories(
        origins,
        dep_library_dirs,
    ))
    directories.extend(_solib_sibling_search_directories(dep_library_dirs))
    return _dedupe_strings(directories)

def derive_runtime_library_search_directories(ctx, outputs):
    """Derives runtime library search directories for an enabled target.

    The caller is responsible for policy checks before calling this helper:
    runtime search should already be enabled, unsupported platforms should
    already be rejected, outputs must be available, and additional runtime
    origins must be rejected when no declared output can recover INSTALLDIR in
    `File.short_path` space.

    This derives the runtime search path for declared executables and shared
    libraries of the foreign_cc target by calculating the relative path from
    those artifacts to the target's own shared libraries and its dep's and
    dynamic_deps's shared libraries.

    For each place an output can be *loaded from* (an "origin" / FROM), write a
    relative path to each place its libraries live (a "library dir" / TO). That
    relative string becomes an `$ORIGIN`-relative RPATH entry (`$ORIGIN` on ELF,
    `@loader_path` on Darwin), e.g. a binary in `bin/` needing a lib in `lib/`
    yields `../lib`.

    Two passes share the same TO lists but differ only in their FROM:

        pass         FROM (origins)      TO (library dirs)
        ----------   -----------------   ----------------------------
        shared       this rule's libs    own libs + deps' libs
        executable   this rule's bins    own libs + deps' libs

    If any `additional_*_runtime_library_search_origins` are declared, they are
    added to the respective `FROM (origins)`.

    An empty FROM (e.g. no binaries) yields no paths for that pass. Everything
    else here is edge-case plumbing layered on this core:
    - `additional_origins` adds extra FROMs
    - `_solib_sibling_*` handles Bazel's `_solib_*` symlink dirs
    - `../` -> `external/` reconciles runfiles vs execroot for external repos
    - INSTALLDIR recovery backs the install root out of a File.short_path.

    Args:
      ctx: Rule context.
      outputs: Framework-declared outputs.

    Returns:
      A struct with `shared_dirs` and `executable_dirs` depset fields containing
      loader-relative runtime library search directories.
    """

    shared_files = outputs.libraries.shared_libraries
    binary_files = outputs.out_binary_files

    self_library_dirs = _dirs_from_files(shared_files)
    dep_library_dirs = _dynamic_library_dirs_from_deps(ctx)

    additional_dynamic_origins = getattr(ctx.attr, "additional_dynamic_runtime_library_search_origins", [])
    additional_executable_origins = getattr(ctx.attr, "additional_executable_runtime_library_search_origins", [])

    installdir = None
    if additional_dynamic_origins or additional_executable_origins:
        installdir = _installdir_from_outputs(ctx, outputs)

    shared_rpaths = _runtime_library_search_directories_for_outputs(
        shared_files,
        additional_dynamic_origins,
        installdir,
        self_library_dirs,
        dep_library_dirs,
    )

    executable_rpaths = _runtime_library_search_directories_for_outputs(
        binary_files,
        additional_executable_origins,
        installdir,
        self_library_dirs,
        dep_library_dirs,
    )

    return struct(
        shared_dirs = depset(shared_rpaths),
        executable_dirs = depset(executable_rpaths),
    )

export_for_test = struct(
    installdir_from_outputs = _installdir_from_outputs,
    search_directories = _search_directories,
    solib_sibling_search_directories = _solib_sibling_search_directories,
)
