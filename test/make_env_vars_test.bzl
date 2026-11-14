"""Unit tests for Make environment variable helpers."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:cc_toolchain_util.bzl", "export_for_test")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:make_env_vars.bzl", "get_ldflags_make_vars")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:make_script.bzl", "create_make_script")

def _empty_inputs():
    return struct(
        libs = [],
        include_dirs = [],
        headers = [],
    )

def _ldflags_vars_include_dynamic_modules_test(ctx):
    env = unittest.begin(ctx)

    flags = struct(
        cxx_linker_executable = ["EXE"],
        cxx_linker_shared = ["SHARED"],
        cxx_linker_dynamic_module = ["MODULE"],
    )

    result = get_ldflags_make_vars(
        [],
        [],
        ["MODULE_LDFLAGS"],
        "workspace",
        flags,
        {},
        [],
        _empty_inputs(),
        False,
    )

    asserts.equals(env, "MODULE_LDFLAGS=\"MODULE\"", result)

    return unittest.end(env)

def _ldflags_vars_keep_link_categories_independent_test(ctx):
    env = unittest.begin(ctx)

    flags = struct(
        cxx_linker_executable = ["EXE"],
        cxx_linker_shared = ["SHARED"],
        cxx_linker_dynamic_module = ["MODULE"],
    )

    result = get_ldflags_make_vars(
        ["LDFLAGS"],
        ["SHARED_LDFLAGS"],
        ["MODULE_LDFLAGS"],
        "workspace",
        flags,
        {},
        [],
        _empty_inputs(),
        False,
    )

    asserts.equals(env, "LDFLAGS=\"EXE\" SHARED_LDFLAGS=\"SHARED\" MODULE_LDFLAGS=\"MODULE\"", result)

    return unittest.end(env)

def _make_runtime_vars_test(ctx):
    env = unittest.begin(ctx)

    static_libraries = ["external/runtime/libc++.a", "external/runtime/libunwind.a"]
    dynamic_libraries = ["external/runtime/libc++.so.1", "external/runtime/libc++abi.so.1", "external/unwind/libunwind.so.1"]
    for runtime_paths, dynamic_runtime_paths, expected_args in [
        ([], [], ""),
        (
            static_libraries,
            [],
            r' RULES_FOREIGN_CC_RUNTIME_LIBS="\"$$EXT_BUILD_ROOT$$/external/runtime/libc++.a\" \"$$EXT_BUILD_ROOT$$/external/runtime/libunwind.a\""',
        ),
        (
            dynamic_libraries,
            dynamic_libraries,
            r' RULES_FOREIGN_CC_RUNTIME_LIBS="\"$$EXT_BUILD_ROOT$$/external/runtime/libc++.so.1\" \"$$EXT_BUILD_ROOT$$/external/runtime/libc++abi.so.1\" \"$$EXT_BUILD_ROOT$$/external/unwind/libunwind.so.1\""' +
            ' RULES_FOREIGN_CC_RUNTIME_LIBRARY_PATH="$$EXT_BUILD_ROOT$$/external/runtime:$$EXT_BUILD_ROOT$$/external/unwind"',
        ),
    ]:
        script = create_make_script(
            workspace_name = "workspace",
            tools = struct(cxx_linker_static = "", cc = "", cxx = "", ld = ""),
            flags = struct(cxx_linker_executable = ["-link-flag"]),
            root = "project",
            env_vars = {},
            deps = [],
            inputs = struct(ext_build_dirs = [], libs = [], include_dirs = [], headers = []),
            make_prefix = "",
            make_path = "make",
            make_targets = ["all", "install"],
            make_args = "V=1",
            make_install_prefix = "$$INSTALLDIR$$",
            executable_ldflags_vars = ["EXE_LDFLAGS"],
            shared_ldflags_vars = [],
            dynamic_module_ldflags_vars = [],
            is_msvc = False,
            runtime_paths = runtime_paths,
            dynamic_runtime_paths = dynamic_runtime_paths,
        )

        asserts.equals(env, [
            'LDFLAGS="-link-flag" RANLIB=":" CPPFLAGS="" make EXE_LDFLAGS="-link-flag" all V=1' + expected_args + " PREFIX=$$INSTALLDIR$$",
            'LDFLAGS="-link-flag" RANLIB=":" CPPFLAGS="" make EXE_LDFLAGS="-link-flag" install V=1' + expected_args + " PREFIX=$$INSTALLDIR$$",
        ], [line for line in script if " make " in line])

    return unittest.end(env)

def _dynamic_module_link_flags_strip_darwin_library_flags_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.dynamic_module_link_flags(
        ["-shared", "-dynamiclib", "-Wl,-rpath,@loader_path/lib"],
        True,
    )

    asserts.equals(env, ["-Wl,-rpath,@loader_path/lib"], result)

    return unittest.end(env)

def _dynamic_module_link_flags_preserve_non_darwin_flags_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.dynamic_module_link_flags(
        ["-shared", "-Wl,-rpath,$ORIGIN/lib"],
        False,
    )

    asserts.equals(env, ["-shared", "-Wl,-rpath,$ORIGIN/lib"], result)

    return unittest.end(env)

ldflags_vars_include_dynamic_modules_test = unittest.make(_ldflags_vars_include_dynamic_modules_test)
ldflags_vars_keep_link_categories_independent_test = unittest.make(_ldflags_vars_keep_link_categories_independent_test)
make_runtime_vars_test = unittest.make(_make_runtime_vars_test)
dynamic_module_link_flags_strip_darwin_library_flags_test = unittest.make(_dynamic_module_link_flags_strip_darwin_library_flags_test)
dynamic_module_link_flags_preserve_non_darwin_flags_test = unittest.make(_dynamic_module_link_flags_preserve_non_darwin_flags_test)

def make_env_vars_test_suite():
    unittest.suite(
        "make_env_vars_test_suite",
        partial.make(ldflags_vars_include_dynamic_modules_test, size = "small"),
        partial.make(ldflags_vars_keep_link_categories_independent_test, size = "small"),
        partial.make(make_runtime_vars_test, size = "small"),
        partial.make(dynamic_module_link_flags_strip_darwin_library_flags_test, size = "small"),
        partial.make(dynamic_module_link_flags_preserve_non_darwin_flags_test, size = "small"),
    )
