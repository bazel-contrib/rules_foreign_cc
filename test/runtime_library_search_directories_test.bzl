"""Unit tests for runtime library search directory helpers."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:runtime_library_search_directories.bzl", "export_for_test")

def _ctx(
        name = "python",
        lib_name = "",
        package = "pkg",
        repo_name = "",
        out_lib_dir = "lib",
        out_bin_dir = "bin",
        out_shared_libs = [],
        out_binaries = [],
        out_data_dirs = [],
        additional_dynamic_origins = [],
        additional_executable_origins = [],
        enable_runtime_library_search_directories = False,
        include_self_runtime_library_search_directories = False,
        runtime_library_search_mode = "all"):
    return struct(
        attr = struct(
            additional_dynamic_runtime_library_search_origins = additional_dynamic_origins,
            additional_executable_runtime_library_search_origins = additional_executable_origins,
            enable_runtime_library_search_directories = enable_runtime_library_search_directories,
            include_self_runtime_library_search_directories = include_self_runtime_library_search_directories,
            lib_name = lib_name,
            name = name,
            out_bin_dir = out_bin_dir,
            out_binaries = out_binaries,
            out_data_dirs = out_data_dirs,
            out_lib_dir = out_lib_dir,
            out_shared_libs = out_shared_libs,
            runtime_library_search_mode = runtime_library_search_mode,
        ),
        label = struct(
            package = package,
            repo_name = repo_name,
        ),
    )

def _default_dynamic_origin_only_when_out_shared_libs_exist_test(ctx):
    env = unittest.begin(ctx)

    with_shared_libs = export_for_test.runtime_library_search_directories(_ctx(
        enable_runtime_library_search_directories = True,
        include_self_runtime_library_search_directories = True,
        out_shared_libs = ["libpython3.10.so"],
        runtime_library_search_mode = "shared",
    ))
    without_shared_libs = export_for_test.runtime_library_search_directories(_ctx(
        enable_runtime_library_search_directories = True,
        include_self_runtime_library_search_directories = True,
        out_data_dirs = ["lib/python3.10/lib-dynload"],
        runtime_library_search_mode = "shared",
    ))

    asserts.equals(env, ["."], with_shared_libs.shared.to_list())
    asserts.equals(env, [], without_shared_libs.shared.to_list())

    return unittest.end(env)

def _default_executable_origin_only_when_out_binaries_exist_test(ctx):
    env = unittest.begin(ctx)

    with_binaries = export_for_test.runtime_library_search_directories(_ctx(
        enable_runtime_library_search_directories = True,
        include_self_runtime_library_search_directories = True,
        out_binaries = ["python3.10"],
        out_shared_libs = ["libpython3.10.so"],
        runtime_library_search_mode = "executable",
    ))
    without_binaries = export_for_test.runtime_library_search_directories(_ctx(
        enable_runtime_library_search_directories = True,
        include_self_runtime_library_search_directories = True,
        out_data_dirs = ["bin"],
        out_shared_libs = ["libpython3.10.so"],
        runtime_library_search_mode = "executable",
    ))

    asserts.equals(env, ["../lib"], with_binaries.executable.to_list())
    asserts.equals(env, [], without_binaries.executable.to_list())

    return unittest.end(env)

def _additional_dynamic_origins_do_not_affect_executable_origins_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.runtime_library_search_directories(_ctx(
        additional_dynamic_origins = ["lib/python3.10/lib-dynload"],
        enable_runtime_library_search_directories = True,
        include_self_runtime_library_search_directories = True,
        out_binaries = ["python3.10"],
        out_shared_libs = ["libpython3.10.so"],
        runtime_library_search_mode = "executable",
    ))

    asserts.equals(env, ["../lib"], result.executable.to_list())

    return unittest.end(env)

def _additional_executable_origins_do_not_affect_dynamic_origins_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.runtime_library_search_directories(_ctx(
        additional_executable_origins = ["libexec"],
        enable_runtime_library_search_directories = True,
        include_self_runtime_library_search_directories = True,
        out_shared_libs = ["libpython3.10.so"],
        runtime_library_search_mode = "shared",
    ))

    asserts.equals(env, ["."], result.shared.to_list())

    return unittest.end(env)

def _additional_origins_are_install_tree_relative_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.runtime_library_search_directories(_ctx(
        additional_dynamic_origins = ["lib/python3.10/lib-dynload"],
        enable_runtime_library_search_directories = True,
        include_self_runtime_library_search_directories = True,
        out_shared_libs = ["libpython3.10.so"],
        runtime_library_search_mode = "shared",
    ))

    asserts.equals(
        env,
        [
            ".",
            "../..",
        ],
        result.shared.to_list(),
    )

    return unittest.end(env)

def _additional_executable_origins_are_install_tree_relative_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.runtime_library_search_directories(_ctx(
        additional_executable_origins = ["libexec/python"],
        enable_runtime_library_search_directories = True,
        include_self_runtime_library_search_directories = True,
        out_binaries = ["python3.10"],
        out_shared_libs = ["libpython3.10.so"],
        runtime_library_search_mode = "executable",
    ))

    asserts.equals(
        env,
        [
            "../lib",
            "../../lib",
        ],
        result.executable.to_list(),
    )

    return unittest.end(env)

def _external_repo_origins_include_repo_prefix_test(ctx):
    env = unittest.begin(ctx)

    external_repo_ctx = _ctx(
        package = "third_party/python",
        repo_name = "python_repo",
    )

    asserts.equals(
        env,
        [
            "../python_repo/third_party/python/python/lib",
            "../python_repo/third_party/python/python/lib/python3.10/lib-dynload",
        ],
        [
            export_for_test.install_tree_origin_short_path(external_repo_ctx, "lib"),
            export_for_test.install_tree_origin_short_path(external_repo_ctx, "lib/python3.10/lib-dynload"),
        ],
    )

    return unittest.end(env)

def _ignored_attrs_use_new_origin_names_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.ignored_attrs(_ctx(
        additional_dynamic_origins = ["lib/python3.10/lib-dynload"],
        additional_executable_origins = ["bin/tools"],
    ))

    asserts.equals(
        env,
        [
            "additional_dynamic_runtime_library_search_origins",
            "additional_executable_runtime_library_search_origins",
        ],
        result,
    )

    return unittest.end(env)

def _ignored_attrs_include_self_origin_name_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.ignored_attrs(_ctx(
        include_self_runtime_library_search_directories = True,
    ))

    asserts.equals(
        env,
        ["include_self_runtime_library_search_directories"],
        result,
    )

    return unittest.end(env)

def _mode_includes_selected_modes_test(ctx):
    env = unittest.begin(ctx)

    shared_only = _ctx(runtime_library_search_mode = "shared")
    executable_only = _ctx(runtime_library_search_mode = "executable")
    all_modes = _ctx(runtime_library_search_mode = "all")

    asserts.true(env, export_for_test.mode_includes(
        shared_only,
        "shared",
    ))
    asserts.false(env, export_for_test.mode_includes(
        shared_only,
        "executable",
    ))
    asserts.false(env, export_for_test.mode_includes(
        executable_only,
        "shared",
    ))
    asserts.true(env, export_for_test.mode_includes(
        executable_only,
        "executable",
    ))
    asserts.true(env, export_for_test.mode_includes(
        all_modes,
        "shared",
    ))
    asserts.true(env, export_for_test.mode_includes(
        all_modes,
        "executable",
    ))

    return unittest.end(env)

def _self_runtime_search_directories_are_disabled_by_default_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.runtime_library_search_directories(_ctx(
        enable_runtime_library_search_directories = True,
        out_binaries = ["python3.10"],
        out_shared_libs = ["libpython3.10.so"],
    ))

    asserts.equals(env, [], result.shared.to_list())
    asserts.equals(env, [], result.executable.to_list())

    return unittest.end(env)

def _self_runtime_search_directories_use_default_paths_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.runtime_library_search_directories(_ctx(
        enable_runtime_library_search_directories = True,
        include_self_runtime_library_search_directories = True,
        out_binaries = ["python3.10"],
        out_shared_libs = ["libpython3.10.so"],
    ))

    asserts.equals(env, ["."], result.shared.to_list())
    asserts.equals(env, ["../lib"], result.executable.to_list())

    return unittest.end(env)

def _self_runtime_search_directories_use_custom_paths_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.runtime_library_search_directories(_ctx(
        enable_runtime_library_search_directories = True,
        include_self_runtime_library_search_directories = True,
        out_bin_dir = "tools/bin",
        out_binaries = ["python3.10"],
        out_lib_dir = "lib64",
        out_shared_libs = ["libpython3.10.so"],
    ))

    asserts.equals(env, ["."], result.shared.to_list())
    asserts.equals(env, ["../../lib64"], result.executable.to_list())

    return unittest.end(env)

def _self_runtime_search_directories_include_additional_dynamic_origins_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.runtime_library_search_directories(_ctx(
        additional_dynamic_origins = ["lib/python3.10/lib-dynload"],
        enable_runtime_library_search_directories = True,
        include_self_runtime_library_search_directories = True,
        out_shared_libs = ["libpython3.10.so"],
    ))

    asserts.equals(env, [".", "../.."], result.shared.to_list())

    return unittest.end(env)

def _self_runtime_search_directories_respect_mode_test(ctx):
    env = unittest.begin(ctx)

    shared_only = export_for_test.runtime_library_search_directories(_ctx(
        enable_runtime_library_search_directories = True,
        include_self_runtime_library_search_directories = True,
        out_binaries = ["python3.10"],
        out_shared_libs = ["libpython3.10.so"],
        runtime_library_search_mode = "shared",
    ))
    executable_only = export_for_test.runtime_library_search_directories(_ctx(
        enable_runtime_library_search_directories = True,
        include_self_runtime_library_search_directories = True,
        out_binaries = ["python3.10"],
        out_shared_libs = ["libpython3.10.so"],
        runtime_library_search_mode = "executable",
    ))

    asserts.equals(env, ["."], shared_only.shared.to_list())
    asserts.equals(env, None, shared_only.executable)
    asserts.equals(env, None, executable_only.shared)
    asserts.equals(env, ["../lib"], executable_only.executable.to_list())

    return unittest.end(env)

def _runtime_search_directories_dedupe_dynamic_library_dirs_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.search_directories_for_dynamic_libraries(
        ["pkg/python/lib"],
        [
            "pkg/python/lib/libpython3.10.so",
            "pkg/python/lib/libother.so",
        ],
    )

    asserts.equals(env, ["."], result)

    return unittest.end(env)

def _solib_sibling_rpath_uses_all_middle_path_segments_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.solib_sibling_search_directory(
        "_solib_local/_Uthirdparty_Ssqlite/deeper/libsqlite3.so",
    )

    asserts.equals(env, "../_Uthirdparty_Ssqlite/deeper", result)

    return unittest.end(env)

def _solib_dynamic_library_gets_output_and_sibling_rpaths_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.search_directories_for_dynamic_libraries(
        ["thirdparty/python39/python39/lib/python3.9/lib-dynload"],
        ["_solib_local/_Uthirdparty_Sbzip2/libbz2.so"],
    )

    asserts.equals(
        env,
        [
            "../../../../../../_solib_local/_Uthirdparty_Sbzip2",
            "../_Uthirdparty_Sbzip2",
        ],
        result,
    )

    return unittest.end(env)

def _non_solib_path_has_no_solib_sibling_rpath_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.solib_sibling_search_directory(
        "pkg/python/lib/libpython3.10.so",
    )

    asserts.equals(env, None, result)

    return unittest.end(env)

def _solib_path_without_directory_has_no_solib_sibling_rpath_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.solib_sibling_search_directory(
        "_solib_local/libpython3.10.so",
    )

    asserts.equals(env, None, result)

    return unittest.end(env)

default_dynamic_origin_only_when_out_shared_libs_exist_test = unittest.make(
    _default_dynamic_origin_only_when_out_shared_libs_exist_test,
)
default_executable_origin_only_when_out_binaries_exist_test = unittest.make(
    _default_executable_origin_only_when_out_binaries_exist_test,
)
additional_dynamic_origins_do_not_affect_executable_origins_test = unittest.make(
    _additional_dynamic_origins_do_not_affect_executable_origins_test,
)
additional_executable_origins_do_not_affect_dynamic_origins_test = unittest.make(
    _additional_executable_origins_do_not_affect_dynamic_origins_test,
)
additional_origins_are_install_tree_relative_test = unittest.make(
    _additional_origins_are_install_tree_relative_test,
)
additional_executable_origins_are_install_tree_relative_test = unittest.make(
    _additional_executable_origins_are_install_tree_relative_test,
)
external_repo_origins_include_repo_prefix_test = unittest.make(
    _external_repo_origins_include_repo_prefix_test,
)
ignored_attrs_use_new_origin_names_test = unittest.make(
    _ignored_attrs_use_new_origin_names_test,
)
ignored_attrs_include_self_origin_name_test = unittest.make(
    _ignored_attrs_include_self_origin_name_test,
)
mode_includes_selected_modes_test = unittest.make(
    _mode_includes_selected_modes_test,
)
self_runtime_search_directories_are_disabled_by_default_test = unittest.make(
    _self_runtime_search_directories_are_disabled_by_default_test,
)
self_runtime_search_directories_use_default_paths_test = unittest.make(
    _self_runtime_search_directories_use_default_paths_test,
)
self_runtime_search_directories_use_custom_paths_test = unittest.make(
    _self_runtime_search_directories_use_custom_paths_test,
)
self_runtime_search_directories_include_additional_dynamic_origins_test = unittest.make(
    _self_runtime_search_directories_include_additional_dynamic_origins_test,
)
self_runtime_search_directories_respect_mode_test = unittest.make(
    _self_runtime_search_directories_respect_mode_test,
)
runtime_search_directories_dedupe_dynamic_library_dirs_test = unittest.make(
    _runtime_search_directories_dedupe_dynamic_library_dirs_test,
)
solib_sibling_rpath_uses_all_middle_path_segments_test = unittest.make(
    _solib_sibling_rpath_uses_all_middle_path_segments_test,
)
solib_dynamic_library_gets_output_and_sibling_rpaths_test = unittest.make(
    _solib_dynamic_library_gets_output_and_sibling_rpaths_test,
)
non_solib_path_has_no_solib_sibling_rpath_test = unittest.make(
    _non_solib_path_has_no_solib_sibling_rpath_test,
)
solib_path_without_directory_has_no_solib_sibling_rpath_test = unittest.make(
    _solib_path_without_directory_has_no_solib_sibling_rpath_test,
)

def runtime_library_search_directories_test_suite():
    unittest.suite(
        "runtime_library_search_directories_test_suite",
        partial.make(default_dynamic_origin_only_when_out_shared_libs_exist_test, size = "small"),
        partial.make(default_executable_origin_only_when_out_binaries_exist_test, size = "small"),
        partial.make(additional_dynamic_origins_do_not_affect_executable_origins_test, size = "small"),
        partial.make(additional_executable_origins_do_not_affect_dynamic_origins_test, size = "small"),
        partial.make(additional_origins_are_install_tree_relative_test, size = "small"),
        partial.make(additional_executable_origins_are_install_tree_relative_test, size = "small"),
        partial.make(external_repo_origins_include_repo_prefix_test, size = "small"),
        partial.make(ignored_attrs_use_new_origin_names_test, size = "small"),
        partial.make(ignored_attrs_include_self_origin_name_test, size = "small"),
        partial.make(mode_includes_selected_modes_test, size = "small"),
        partial.make(self_runtime_search_directories_are_disabled_by_default_test, size = "small"),
        partial.make(self_runtime_search_directories_use_default_paths_test, size = "small"),
        partial.make(self_runtime_search_directories_use_custom_paths_test, size = "small"),
        partial.make(self_runtime_search_directories_include_additional_dynamic_origins_test, size = "small"),
        partial.make(self_runtime_search_directories_respect_mode_test, size = "small"),
        partial.make(runtime_search_directories_dedupe_dynamic_library_dirs_test, size = "small"),
        partial.make(solib_sibling_rpath_uses_all_middle_path_segments_test, size = "small"),
        partial.make(solib_dynamic_library_gets_output_and_sibling_rpaths_test, size = "small"),
        partial.make(non_solib_path_has_no_solib_sibling_rpath_test, size = "small"),
        partial.make(solib_path_without_directory_has_no_solib_sibling_rpath_test, size = "small"),
    )
