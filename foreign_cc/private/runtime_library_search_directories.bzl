"""Helpers for deriving loader-relative runtime library search paths."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@rules_cc//cc:defs.bzl", "CcInfo")
load("@rules_cc//cc/common:cc_shared_library_info.bzl", "CcSharedLibraryInfo")

# Definitions for terms used throughout this file:
#
# origin:
# Directory where a binary or shared library may be loaded from at runtime.
# Runtime search paths are written relative to this directory:
# `$ORIGIN` on ELF and `@loader_path` on Darwin.
#
# origin_short_path:
# Concrete `File.short_path` directory for an origin. For example,
# "pkg/python/bin/python3.10" contributes "pkg/python/bin" as the
# origin_short_path. A user-defined additional origin such as
# "lib/python3.10/lib-dynload" is already relative to INSTALLDIR; if
# INSTALLDIR is "pkg/python", it contributes
# "pkg/python/lib/python3.10/lib-dynload" as the origin_short_path.

RUNTIME_LIBRARY_SEARCH_DIRECTORY_ATTRIBUTES = {
    "additional_dynamic_runtime_library_search_origins": attr.string_list(
        doc = (
            "Additional install-tree-relative origins for shared-library " +
            "link actions. Values are relative to this rule's install " +
            "directory and should not include lib_name or the rule name. " +
            "For each origin, runtime library search directories are derived " +
            "so shared libraries loaded from that origin can find shared " +
            "libraries from deps, dynamic_deps, and this rule's own declared " +
            "shared-library outputs."
        ),
        mandatory = False,
        default = [],
    ),
    "additional_executable_runtime_library_search_origins": attr.string_list(
        doc = (
            "Additional install-tree-relative origins for executable link " +
            "actions. Values are relative to this rule's install directory " +
            "and should not include lib_name or the rule name. For each " +
            "origin, runtime library search directories are derived so " +
            "executables loaded from that origin can find shared libraries " +
            "from deps, dynamic_deps, and this rule's own declared " +
            "shared-library outputs."
        ),
        mandatory = False,
        default = [],
    ),
    "runtime_library_search_directories": attr.string(
        doc = (
            "Controls whether this target derives runtime library search " +
            "directories. Use 'auto' to follow the global " +
            "@rules_foreign_cc//foreign_cc/settings:runtime_library_search_directories " +
            "build setting, 'enabled' to force it on for this target, or " +
            "'disabled' to force it off. This is not supported for Windows " +
            "C++ toolchains. On macOS, derived runtime search paths also " +
            "require compatible Mach-O @rpath install names and load " +
            "commands. This feature passes runtime search directories to " +
            "link actions, but does not generally rewrite installed dylib " +
            "IDs or load commands after the upstream install step. Upstream " +
            "builds may need to emit or preserve @rpath/... install names."
        ),
        mandatory = False,
        values = ["auto", "enabled", "disabled"],
        default = "auto",
    ),
    "_runtime_library_search_directories": attr.label(
        default = Label("//foreign_cc/settings:runtime_library_search_directories"),
        providers = [BuildSettingInfo],
    ),
}

def _path_segments(path):
    normalized = paths.normalize(path)
    if normalized == ".":
        return []
    return [segment for segment in normalized.split("/") if segment]

def _common_prefix_length(left, right):
    max_common_segment_count = len(left)
    if len(right) < max_common_segment_count:
        max_common_segment_count = len(right)

    for index in range(max_common_segment_count):
        if left[index] != right[index]:
            return index

    return max_common_segment_count

# Return the path fragment appended after `$ORIGIN` or `@loader_path`. For
# example, from "pkg/python/bin" to "pkg/python/lib" this returns "../lib".'
def _relative_path(from_path, to_path):
    from_segments = _path_segments(from_path)
    to_segments = _path_segments(to_path)
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

def _dynamic_library_origin_short_paths_from_deps(ctx):
    dynamic_library_origin_short_paths = []
    for dep in getattr(ctx.attr, "deps", []) + getattr(ctx.attr, "dynamic_deps", []):
        for dynamic_library in _dynamic_libraries_from_dep(dep):
            dynamic_library_origin_short_paths.append(paths.dirname(dynamic_library.short_path))
    return _dedupe_strings(dynamic_library_origin_short_paths)

# Declared output files provide the default origins. A binary at
# "pkg/python/bin/python3.10" contributes "pkg/python/bin"; a shared library at
# "pkg/python/lib/libpython.so" contributes "pkg/python/lib".
def _origin_short_paths_from_files(files):
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
def _derive_installdir_short_path(output_file, install_path):
    install_path = install_path.lstrip("/")
    suffix = "/" + install_path
    short_path = output_file.short_path

    if short_path.endswith(suffix):
        return short_path[:-len(suffix)]

    fail("Output {} does not end with install-relative path {}".format(
        short_path,
        install_path,
    ))

def _installdir_short_path_from_outputs(ctx, outputs):
    if outputs.libraries.shared_libraries:
        return _derive_installdir_short_path(
            outputs.libraries.shared_libraries[0],
            _install_path(ctx.attr.out_lib_dir, ctx.attr.out_shared_libs[0]),
        )

    if outputs.out_binary_files:
        return _derive_installdir_short_path(
            outputs.out_binary_files[0],
            _install_path(ctx.attr.out_bin_dir, ctx.attr.out_binaries[0]),
        )

    return None

# Users specify extra origins relative to INSTALLDIR, for example
# "lib/python3.10/lib-dynload". Expand those into the same `File.short_path`
# space as declared outputs.
def _origin_short_paths_from_install_tree(installdir_short_path, install_tree_origins):
    if install_tree_origins and installdir_short_path == None:
        fail(
            "Additional runtime library search origins require at least one " +
            "declared shared library or binary output.",
        )

    origin_short_paths = []
    for install_tree_origin in install_tree_origins:
        origin = install_tree_origin.lstrip("/")
        origin_short_paths.append(paths.join(
            installdir_short_path,
            origin,
        ) if origin else installdir_short_path)
    return origin_short_paths

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
def _origin_short_paths(installdir_short_path, output_files, additional_origins):
    return _dedupe_strings(
        _origin_short_paths_from_files(output_files) +
        _origin_short_paths_from_install_tree(
            installdir_short_path,
            additional_origins,
        ),
    )

def _search_directories(origin_short_paths, library_origin_short_paths):
    directories = []
    for origin_short_path in origin_short_paths:
        for library_origin_short_path in library_origin_short_paths:
            directories.append(_relative_path(origin_short_path, library_origin_short_path))
    return directories

def _origin_short_paths_from_dynamic_libraries(dep_library_short_paths):
    return _dedupe_strings([
        paths.dirname(dep_library_short_path)
        for dep_library_short_path in dep_library_short_paths
    ])

# Return the sibling-solib search entry for a dependent dynamic library origin.
# Bazel often links against solib symlinks instead of real output paths, and a
# sibling entry lets a library loaded from one solib artifact directory find a
# dependency in another.
#
# For example, for a dep_library_origin_short_path of:
#   "_solib_k8/_Uthirdparty_Szlib"
#
# This will return the runtime search path of relative to _solib_k8:
#   "../_Uthirdparty_Szlib"
#
# Inputs without a solib root and artifact directory return None:
#   "pkg/zlib/lib" -> None
#   "_solib_k8" -> None
#
# This helper assume that the path of the library (the ones we are building in
# the rule) needing the solib sibling search directory is exactly 1 directory
# deep under the solib root. e.g.
# "_solib_k8/_Uthirdparty_Szlib/libz.so" or
# "_solib_k8/_Uthirdparty_Sopenssl__Slib/libcrypto.so"
#
# While this is true for most scenarios, edge cases does exist. One example of
# this is to set "dynamic_library_symlink_path" when using
# cc_common.create_library_to_link. However, it is
# not possible to account for this without knowing the solib path of library
# we are building in advance. So this is our best effort.
def _solib_sibling_search_directory(dep_library_origin_short_path):
    segments = _path_segments(dep_library_origin_short_path)
    if len(segments) < 2 or not segments[0].startswith("_solib_"):
        return None

    artifact_dir_under_solib = "/".join(segments[1:])
    if not artifact_dir_under_solib:
        return None

    return "../" + artifact_dir_under_solib

def _solib_sibling_search_directories(dep_library_origin_short_paths):
    directories = []
    for dep_library_origin_short_path in dep_library_origin_short_paths:
        solib_sibling_directory = _solib_sibling_search_directory(dep_library_origin_short_path)
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
        installdir_short_path,
        self_library_origin_short_paths,
        dep_library_origin_short_paths,
        output_files,
        additional_origins):
    origin_short_paths = _origin_short_paths(
        installdir_short_path,
        output_files,
        additional_origins,
    )

    directories = []
    directories.extend(_search_directories(origin_short_paths, self_library_origin_short_paths))
    directories.extend(_search_directories(
        origin_short_paths,
        dep_library_origin_short_paths,
    ))
    directories.extend(_solib_sibling_search_directories(dep_library_origin_short_paths))
    return _dedupe_strings(directories)

def _runtime_library_search_directories_enabled(ctx):
    value = getattr(ctx.attr, "runtime_library_search_directories", "disabled")
    if value == "enabled":
        return True
    if value == "disabled":
        return False

    setting = getattr(ctx.attr, "_runtime_library_search_directories", None)
    return setting[BuildSettingInfo].value == "enabled"

def _ignored_attrs(ctx):
    ignored_attrs = []
    for attr_name in [
        "additional_dynamic_runtime_library_search_origins",
        "additional_executable_runtime_library_search_origins",
    ]:
        if getattr(ctx.attr, attr_name, []):
            ignored_attrs.append(attr_name)
    return ignored_attrs

# buildifier: disable=print
def _warn_if_attrs_ignored(ctx):
    ignored_attrs = _ignored_attrs(ctx)
    if ignored_attrs:
        print((
            "WARNING: {} sets runtime_library_search attrs ({}) but " +
            "runtime_library_search_directories is disabled; " +
            "ignoring runtime_library_search attrs."
        ).format(ctx.label, ", ".join(ignored_attrs)))

def runtime_library_search_directories(ctx, outputs):
    """Returns runtime library search directories for link actions.

    Args:
      ctx: Rule context.
      outputs: Framework-declared outputs. Shared libraries and binaries provide
        the default runtime origins; one of them is also used to recover
        INSTALLDIR in `File.short_path` space.

    Returns:
      A struct with `shared` and `executable` depset fields. Each field contains
      runtime library search directories for that link action kind, or None when
      runtime library search directory derivation is disabled.
    """

    if not _runtime_library_search_directories_enabled(ctx):
        _warn_if_attrs_ignored(ctx)
        return struct(shared = None, executable = None)

    if outputs == None:
        fail("Runtime library search directory derivation requires outputs.")

    shared_files = outputs.libraries.shared_libraries
    binary_files = outputs.out_binary_files
    installdir_short_path = _installdir_short_path_from_outputs(ctx, outputs)
    self_library_origin_short_paths = _origin_short_paths_from_files(shared_files)
    dep_library_origin_short_paths = _dynamic_library_origin_short_paths_from_deps(ctx)

    return struct(
        shared = depset(_runtime_library_search_directories_for_outputs(
            installdir_short_path,
            self_library_origin_short_paths,
            dep_library_origin_short_paths,
            shared_files,
            getattr(ctx.attr, "additional_dynamic_runtime_library_search_origins", []),
        )),
        executable = depset(_runtime_library_search_directories_for_outputs(
            installdir_short_path,
            self_library_origin_short_paths,
            dep_library_origin_short_paths,
            binary_files,
            getattr(ctx.attr, "additional_executable_runtime_library_search_origins", []),
        )),
    )

export_for_test = struct(
    runtime_library_search_directories = runtime_library_search_directories,
    runtime_library_search_directories_enabled = _runtime_library_search_directories_enabled,
    origin_short_paths_from_dynamic_libraries = _origin_short_paths_from_dynamic_libraries,
    search_directories = _search_directories,
    solib_sibling_search_directories = _solib_sibling_search_directories,
)
