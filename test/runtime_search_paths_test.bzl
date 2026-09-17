"""Unit tests for runtime library search directory path derivation.

This suite covers pure helper behavior: self-output origins, custom output
directories, install-tree-relative additional origins, data-output install-root
anchors, deduping, solib sibling paths, and external-repo normalization. It
does not instantiate foreign_cc rules or validate analysis-time policy.
"""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private:runtime_library_search_directories.bzl",
    "runtime_library_search_directories",
)

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private:runtime_search_paths.bzl",
    "export_for_test",
)

def _ctx(
        attr = struct(),
        package = "pkg"):
    return struct(
        attr = struct(
            additional_dynamic_runtime_library_search_origins = getattr(attr, "additional_dynamic_runtime_library_search_origins", []),
            additional_executable_runtime_library_search_origins = getattr(attr, "additional_executable_runtime_library_search_origins", []),
            out_bin_dir = getattr(attr, "out_bin_dir", "bin"),
            out_binaries = getattr(attr, "out_binaries", []),
            out_data_dirs = getattr(attr, "out_data_dirs", []),
            out_data_files = getattr(attr, "out_data_files", []),
            out_lib_dir = getattr(attr, "out_lib_dir", "lib"),
            out_shared_libs = getattr(attr, "out_shared_libs", []),
            runtime_library_search_directories = getattr(attr, "runtime_library_search_directories", "disabled"),
        ),
        label = struct(
            package = package,
        ),
    )

def _file(short_path):
    return struct(short_path = short_path)

def _outputs(
        shared_files = [],
        binary_files = [],
        data_dirs = [],
        data_files = []):
    return struct(
        libraries = struct(
            shared_libraries = [_file(short_path) for short_path in shared_files],
        ),
        out_binary_files = [_file(short_path) for short_path in binary_files],
        data_dirs = [_file(short_path) for short_path in data_dirs],
        data_files = [_file(short_path) for short_path in data_files],
    )

def _runtime_library_search_directories(
        ctx,
        shared_files = [],
        binary_files = [],
        data_dirs = [],
        data_files = []):
    return runtime_library_search_directories(
        ctx,
        _outputs(
            shared_files = shared_files,
            binary_files = binary_files,
            data_dirs = data_dirs,
            data_files = data_files,
        ),
    )

def _to_list_or_none(value):
    if value == None:
        return None
    return value.to_list()

def _assert_runtime_library_search_directories(
        env,
        case):
    outputs = getattr(case, "outputs", struct())

    result = _runtime_library_search_directories(
        case.ctx,
        shared_files = getattr(outputs, "shared_files", []),
        binary_files = getattr(outputs, "binary_files", []),
        data_dirs = getattr(outputs, "data_dirs", []),
        data_files = getattr(outputs, "data_files", []),
    )

    asserts.equals(env, case.expected.shared_dirs, _to_list_or_none(result.shared_dirs), "{} shared".format(case.name))
    asserts.equals(env, case.expected.executable_dirs, _to_list_or_none(result.executable_dirs), "{} executable".format(case.name))

def _self_output_origins_are_derived_from_outputs_test(ctx):
    env = unittest.begin(ctx)

    cases = [
        struct(
            name = "shared output",
            ctx = _ctx(attr = struct(
                runtime_library_search_directories = "enabled",
                out_shared_libs = ["libpython3.10.so"],
            )),
            outputs = struct(
                shared_files = ["pkg/python/lib/libpython3.10.so"],
            ),
            expected = struct(
                shared_dirs = ["."],
                executable_dirs = [],
            ),
        ),
        struct(
            name = "data dir output",
            ctx = _ctx(attr = struct(
                runtime_library_search_directories = "enabled",
                out_data_dirs = ["lib/python3.10/lib-dynload"],
            )),
            outputs = struct(
                data_dirs = ["pkg/python/lib/python3.10/lib-dynload"],
            ),
            expected = struct(
                shared_dirs = [],
                executable_dirs = [],
            ),
        ),
        struct(
            name = "binary and shared outputs",
            ctx = _ctx(attr = struct(
                runtime_library_search_directories = "enabled",
                out_binaries = ["python3.10"],
                out_shared_libs = ["libpython3.10.so"],
            )),
            outputs = struct(
                binary_files = ["pkg/python/bin/python3.10"],
                shared_files = ["pkg/python/lib/libpython3.10.so"],
            ),
            expected = struct(
                shared_dirs = ["."],
                executable_dirs = ["../lib"],
            ),
        ),
        struct(
            name = "shared and data outputs",
            ctx = _ctx(attr = struct(
                runtime_library_search_directories = "enabled",
                out_data_dirs = ["bin"],
                out_shared_libs = ["libpython3.10.so"],
            )),
            outputs = struct(
                data_dirs = ["pkg/python/bin"],
                shared_files = ["pkg/python/lib/libpython3.10.so"],
            ),
            expected = struct(
                shared_dirs = ["."],
                executable_dirs = [],
            ),
        ),
    ]

    for case in cases:
        _assert_runtime_library_search_directories(env, case)

    return unittest.end(env)

def _custom_output_dirs_derive_self_output_origins_test(ctx):
    env = unittest.begin(ctx)

    case = struct(
        name = "custom output directories",
        ctx = _ctx(attr = struct(
            runtime_library_search_directories = "enabled",
            out_bin_dir = "tools/bin",
            out_binaries = ["python3.10"],
            out_lib_dir = "lib64",
            out_shared_libs = ["libpython3.10.so"],
        )),
        outputs = struct(
            binary_files = ["pkg/python/tools/bin/python3.10"],
            shared_files = ["pkg/python/lib64/libpython3.10.so"],
        ),
        expected = struct(
            shared_dirs = ["."],
            executable_dirs = ["../../lib64"],
        ),
    )

    _assert_runtime_library_search_directories(env, case)

    return unittest.end(env)

def _additional_origins_are_install_tree_relative_test(ctx):
    env = unittest.begin(ctx)

    cases = [
        struct(
            name = "additional dynamic origin does not affect executable origins",
            ctx = _ctx(attr = struct(
                additional_dynamic_runtime_library_search_origins = ["lib/python3.10/lib-dynload"],
                runtime_library_search_directories = "enabled",
                out_binaries = ["python3.10"],
                out_shared_libs = ["libpython3.10.so"],
            )),
            outputs = struct(
                binary_files = ["pkg/python/bin/python3.10"],
                shared_files = ["pkg/python/lib/libpython3.10.so"],
            ),
            expected = struct(
                shared_dirs = [".", "../.."],
                executable_dirs = ["../lib"],
            ),
        ),
        struct(
            name = "additional executable origin does not affect dynamic origins",
            ctx = _ctx(attr = struct(
                additional_executable_runtime_library_search_origins = ["libexec"],
                runtime_library_search_directories = "enabled",
                out_shared_libs = ["libpython3.10.so"],
            )),
            outputs = struct(
                shared_files = ["pkg/python/lib/libpython3.10.so"],
            ),
            expected = struct(
                shared_dirs = ["."],
                executable_dirs = ["../lib"],
            ),
        ),
        struct(
            name = "self binary output and additional executable origin",
            ctx = _ctx(attr = struct(
                additional_executable_runtime_library_search_origins = ["libexec/bin"],
                runtime_library_search_directories = "enabled",
                out_binaries = ["python3.10"],
                out_shared_libs = ["libpython3.10.so"],
            )),
            outputs = struct(
                binary_files = ["pkg/python/bin/python3.10"],
                shared_files = ["pkg/python/lib/libpython3.10.so"],
            ),
            expected = struct(
                shared_dirs = ["."],
                executable_dirs = ["../lib", "../../lib"],
            ),
        ),
        struct(
            name = "self binary output and additional executable origin but no shared output",
            ctx = _ctx(attr = struct(
                additional_executable_runtime_library_search_origins = ["libexec/bin"],
                runtime_library_search_directories = "enabled",
                out_binaries = ["python3.10"],
            )),
            outputs = struct(
                binary_files = ["pkg/python/bin/python3.10"],
            ),
            expected = struct(
                shared_dirs = [],
                executable_dirs = [],
            ),
        ),
        struct(
            name = "data dir with additional dynamic origin",
            ctx = _ctx(attr = struct(
                additional_dynamic_runtime_library_search_origins = ["lib/python3.10/lib-dynload"],
                runtime_library_search_directories = "enabled",
                out_data_dirs = ["lib/python3.10/lib-dynload"],
            )),
            outputs = struct(
                data_dirs = ["pkg/python/lib/python3.10/lib-dynload"],
            ),
            expected = struct(
                shared_dirs = [],
                executable_dirs = [],
            ),
        ),
        struct(
            name = "data file with additional dynamic origin",
            ctx = _ctx(attr = struct(
                additional_dynamic_runtime_library_search_origins = ["lib/python3.10/lib-dynload"],
                runtime_library_search_directories = "enabled",
                out_data_files = ["lib/python3.10/lib-dynload/ext.so"],
            )),
            outputs = struct(
                data_files = ["pkg/python/lib/python3.10/lib-dynload/ext.so"],
            ),
            expected = struct(
                shared_dirs = [],
                executable_dirs = [],
            ),
        ),
    ]

    for case in cases:
        _assert_runtime_library_search_directories(env, case)

    return unittest.end(env)

def _runtime_search_directories_dedupe_self_library_dirs_test(ctx):
    env = unittest.begin(ctx)

    case = struct(
        name = "duplicate self library dirs",
        ctx = _ctx(attr = struct(
            runtime_library_search_directories = "enabled",
            out_shared_libs = [
                "libpython3.10.so",
                "libother.so",
            ],
        )),
        outputs = struct(
            shared_files = [
                "pkg/python/lib/libpython3.10.so",
                "pkg/python/lib/libother.so",
            ],
        ),
        expected = struct(
            shared_dirs = ["."],
            executable_dirs = [],
        ),
    )

    _assert_runtime_library_search_directories(env, case)

    return unittest.end(env)

def _solib_sibling_search_directories_test(ctx):
    env = unittest.begin(ctx)

    cases = [
        struct(
            name = "solib output and sibling rpaths",
            origins = ["thirdparty/python39/python39/lib/python3.9/lib-dynload"],
            dep_library_dirs = ["_solib_local/_Uthirdparty_Sbzip2"],
            expected = [
                "../../../../../../_solib_local/_Uthirdparty_Sbzip2",
                "../_Uthirdparty_Sbzip2",
            ],
        ),
        struct(
            name = "non-solib output rpath only",
            origins = ["pkg/python/bin"],
            dep_library_dirs = ["pkg/python/lib"],
            expected = ["../lib"],
        ),
        struct(
            name = "solib without directory",
            origins = ["pkg/python/lib"],
            dep_library_dirs = ["_solib_local"],
            expected = ["../../../_solib_local"],
        ),
    ]

    for case in cases:
        result = export_for_test.search_directories(
            case.origins,
            case.dep_library_dirs,
        ) + export_for_test.solib_sibling_search_directories(case.dep_library_dirs)

        asserts.equals(env, case.expected, result, case.name)

    return unittest.end(env)

def _external_repo_origins_use_execroot_relative_rpaths_test(ctx):
    env = unittest.begin(ctx)

    cases = [
        struct(
            name = "main repo output to external repo dependency",
            origins = ["myproj/build/lib"],
            library_dirs = ["../zlib/lib"],
            expected = ["../../../external/zlib/lib"],
        ),
        struct(
            name = "external repo output to external repo dependency",
            origins = ["../consumer/pkg/lib"],
            library_dirs = ["../zlib/lib"],
            expected = ["../../../zlib/lib"],
        ),
    ]

    for case in cases:
        result = export_for_test.search_directories(
            case.origins,
            case.library_dirs,
        )

        asserts.equals(env, case.expected, result, case.name)

    return unittest.end(env)

def _outputs_anchor_installdir_test(ctx):
    env = unittest.begin(ctx)

    cases = [
        struct(
            name = "shared library anchor for installdir",
            ctx = _ctx(attr = struct(
                out_shared_libs = ["libpython3.10.so"],
            )),
            outputs = _outputs(
                shared_files = ["pkg/python/lib/libpython3.10.so"],
            ),
            expected = "pkg/python",
        ),
        struct(
            name = "binary anchor for installdir",
            ctx = _ctx(attr = struct(
                out_binaries = ["python3.10"],
            )),
            outputs = _outputs(
                binary_files = ["pkg/python/bin/python3.10"],
            ),
            expected = "pkg/python",
        ),
        struct(
            name = "data dir anchor for installdir",
            ctx = _ctx(attr = struct(
                out_data_dirs = ["lib/python3.10/lib-dynload"],
            )),
            outputs = _outputs(
                data_dirs = ["pkg/python/lib/python3.10/lib-dynload"],
            ),
            expected = "pkg/python",
        ),
        struct(
            name = "data file anchor for installdir",
            ctx = _ctx(attr = struct(
                out_data_files = ["lib/python3.10/lib-dynload/ext.so"],
            )),
            outputs = _outputs(
                data_files = ["pkg/python/lib/python3.10/lib-dynload/ext.so"],
            ),
            expected = "pkg/python",
        ),
    ]

    for case in cases:
        anchor = export_for_test.installdir_from_outputs(case.ctx, case.outputs)
        asserts.equals(env, case.expected, anchor, case.name)

    return unittest.end(env)

self_output_origins_are_derived_from_outputs_test = unittest.make(
    _self_output_origins_are_derived_from_outputs_test,
)
custom_output_dirs_derive_self_output_origins_test = unittest.make(
    _custom_output_dirs_derive_self_output_origins_test,
)
additional_origins_are_install_tree_relative_test = unittest.make(
    _additional_origins_are_install_tree_relative_test,
)
outputs_anchor_installdir_test = unittest.make(
    _outputs_anchor_installdir_test,
)
runtime_search_directories_dedupe_self_library_dirs_test = unittest.make(
    _runtime_search_directories_dedupe_self_library_dirs_test,
)
solib_sibling_search_directories_test = unittest.make(
    _solib_sibling_search_directories_test,
)
external_repo_origins_use_execroot_relative_rpaths_test = unittest.make(
    _external_repo_origins_use_execroot_relative_rpaths_test,
)

def runtime_library_search_directories_test_suite_paths(name = "runtime_library_search_directories_test_suite_paths"):
    """Declares runtime-library-search helper path tests.

    Args:
      name: Name for the generated unittest suite.
    """

    unittest.suite(
        name,
        partial.make(self_output_origins_are_derived_from_outputs_test, size = "small"),
        partial.make(custom_output_dirs_derive_self_output_origins_test, size = "small"),
        partial.make(additional_origins_are_install_tree_relative_test, size = "small"),
        partial.make(outputs_anchor_installdir_test, size = "small"),
        partial.make(runtime_search_directories_dedupe_self_library_dirs_test, size = "small"),
        partial.make(solib_sibling_search_directories_test, size = "small"),
        partial.make(external_repo_origins_use_execroot_relative_rpaths_test, size = "small"),
    )
