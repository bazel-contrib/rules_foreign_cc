"""Runtime library search directory helpers."""

load("@bazel_features//:features.bzl", "bazel_features")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_cc//cc:defs.bzl", "CcInfo")

CcSharedLibraryInfo = bazel_features.globals.CcSharedLibraryInfo

RUNTIME_LIBRARY_SEARCH_DIRECTORY_ATTRIBUTES = {
    "additional_dynamic_runtime_library_search_origins": attr.string_list(
        doc = (
            "Additional install-tree-relative output origins whose " +
            "runtime library search directories should be derived for " +
            "shared-library link actions. Values are relative to the install " +
            "output root and should not include lib_name or the rule name. " +
            "These are appended to the default out_lib_dir origin when " +
            "out_shared_libs is non-empty."
        ),
        mandatory = False,
        default = [],
    ),
    "additional_executable_runtime_library_search_origins": attr.string_list(
        doc = (
            "Additional install-tree-relative output origins whose " +
            "runtime library search directories should be derived for " +
            "executable link actions. Values are relative to the install " +
            "output root and should not include lib_name or the rule name. " +
            "These are appended to the default out_bin_dir origin when " +
            "out_binaries is non-empty."
        ),
        mandatory = False,
        default = [],
    ),
    "enable_runtime_library_search_directories": attr.bool(
        doc = (
            "When true, enable runtime library search directories derived " +
            "from the dynamic libraries exposed by deps and dynamic_deps. " +
            "When false, runtime-library-search attributes are ignored. " +
            "This is not supported for Windows C++ toolchains."
        ),
        mandatory = False,
        default = False,
    ),
    "include_self_runtime_library_search_directories": attr.bool(
        doc = (
            "When true, add runtime library search directories that let " +
            "this rule's binaries and shared libraries find this rule's own " +
            "shared libraries under out_lib_dir. Ignored unless " +
            "enable_runtime_library_search_directories is true."
        ),
        mandatory = False,
        default = False,
    ),
    "runtime_library_search_mode": attr.string(
        doc = (
            "Link action kinds that receive runtime library search " +
            "directories when runtime search directory derivation is " +
            "enabled."
        ),
        mandatory = False,
        values = ["shared", "executable", "all"],
        default = "all",
    ),
}

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

def _solib_sibling_search_directory(dynamic_library_short_path):
    segments = _path_segments(dynamic_library_short_path)
    if len(segments) < 3 or not segments[0].startswith("_solib_"):
        return None

    artifact_dir_under_solib = "/".join(segments[1:-1])
    if not artifact_dir_under_solib:
        return None

    # If the linked object is loaded through Bazel's solib tree, sibling
    # solib directories are reachable by walking up from the current solib
    # directory and back down to the dependency's solib directory.
    return "../" + artifact_dir_under_solib

def _search_directories_for_dynamic_libraries(
        origin_short_paths,
        dynamic_library_short_paths):
    directories = []
    for dynamic_library_short_path in dynamic_library_short_paths:
        library_dir = paths.dirname(dynamic_library_short_path)
        for origin_short_path in origin_short_paths:
            directories.append(_relative_path(origin_short_path, library_dir))

        solib_sibling_directory = _solib_sibling_search_directory(dynamic_library_short_path)
        if solib_sibling_directory:
            directories.append(solib_sibling_directory)

    return _dedupe_strings(directories)

def _dynamic_library_short_paths_from_deps(ctx):
    dynamic_library_short_paths = []
    for dep in getattr(ctx.attr, "deps", []) + getattr(ctx.attr, "dynamic_deps", []):
        for dynamic_library in _dynamic_libraries_from_dep(dep):
            dynamic_library_short_paths.append(dynamic_library.short_path)
    return dynamic_library_short_paths

def _output_root(ctx):
    return ctx.attr.lib_name or ctx.attr.name

# Convert an install-tree path like "python/lib" to the matching short_path
# shape, e.g. "third_party/python/python/lib" in the main repo or
# "../python_repo/third_party/python/python/lib" from an external repo.
def _output_short_path(ctx, output_subpath):
    parts = []
    if ctx.label.repo_name:
        parts.extend(["..", ctx.label.repo_name])
    if ctx.label.package:
        parts.append(ctx.label.package)
    parts.append(output_subpath)
    return paths.join(*parts)

def _install_tree_origin_short_path(ctx, install_tree_origin):
    return _output_short_path(
        ctx,
        paths.join(_output_root(ctx), install_tree_origin.lstrip("/")),
    )

def _runtime_library_search_directories_for_mode(ctx, mode):
    if mode == "shared":
        install_tree_origins = (
            ([ctx.attr.out_lib_dir] if getattr(ctx.attr, "out_shared_libs", []) else []) +
            getattr(ctx.attr, "additional_dynamic_runtime_library_search_origins", [])
        )
    elif mode == "executable":
        install_tree_origins = (
            ([ctx.attr.out_bin_dir] if getattr(ctx.attr, "out_binaries", []) else []) +
            getattr(ctx.attr, "additional_executable_runtime_library_search_origins", [])
        )
    else:
        fail("Unknown runtime library search mode: {}".format(mode))

    origin_short_paths = _dedupe_strings([
        _install_tree_origin_short_path(ctx, origin)
        for origin in install_tree_origins
    ])
    directories = []

    # Self output directories let this rule's binaries and shared libraries
    # find this rule's own shared libraries under out_lib_dir.
    if (
        getattr(ctx.attr, "include_self_runtime_library_search_directories", False) and
        getattr(ctx.attr, "out_shared_libs", [])
    ):
        self_library_origin_short_path = _install_tree_origin_short_path(ctx, ctx.attr.out_lib_dir)
        for origin_short_path in origin_short_paths:
            directories.append(_relative_path(origin_short_path, self_library_origin_short_path))

    # Dependency output directories let this rule's outputs find linked
    # dynamic libraries exposed by deps and dynamic_deps.
    directories.extend(_search_directories_for_dynamic_libraries(
        origin_short_paths,
        _dynamic_library_short_paths_from_deps(ctx),
    ))
    return _dedupe_strings(directories)

def _mode_includes(ctx, mode):
    runtime_library_search_mode = ctx.attr.runtime_library_search_mode
    return runtime_library_search_mode == "all" or runtime_library_search_mode == mode

def _ignored_attrs(ctx):
    ignored_attrs = []
    if getattr(ctx.attr, "additional_dynamic_runtime_library_search_origins", []):
        ignored_attrs.append("additional_dynamic_runtime_library_search_origins")
    if getattr(ctx.attr, "additional_executable_runtime_library_search_origins", []):
        ignored_attrs.append("additional_executable_runtime_library_search_origins")
    if getattr(ctx.attr, "include_self_runtime_library_search_directories", False):
        ignored_attrs.append("include_self_runtime_library_search_directories")
    return ignored_attrs

# buildifier: disable=print
def _warn_if_attrs_ignored(ctx):
    ignored_attrs = _ignored_attrs(ctx)
    if ignored_attrs:
        print((
            "WARNING: {} sets runtime-library-search attrs ({}) but " +
            "enable_runtime_library_search_directories is false; " +
            "ignoring runtime-library-search attrs."
        ).format(ctx.label, ", ".join(ignored_attrs)))

def runtime_library_search_directories(ctx):
    if not getattr(ctx.attr, "enable_runtime_library_search_directories", False):
        _warn_if_attrs_ignored(ctx)
        return struct(shared = None, executable = None)

    return struct(
        shared = depset(_runtime_library_search_directories_for_mode(ctx, "shared")) if _mode_includes(ctx, "shared") else None,
        executable = depset(_runtime_library_search_directories_for_mode(ctx, "executable")) if _mode_includes(ctx, "executable") else None,
    )

export_for_test = struct(
    ignored_attrs = _ignored_attrs,
    install_tree_origin_short_path = _install_tree_origin_short_path,
    mode_includes = _mode_includes,
    runtime_library_search_directories = runtime_library_search_directories,
    search_directories_for_dynamic_libraries = _search_directories_for_dynamic_libraries,
    solib_sibling_search_directory = _solib_sibling_search_directory,
)
