"""Unit tests for Make environment variable helpers."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:cc_toolchain_util.bzl", "export_for_test")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:make_env_vars.bzl", "get_ldflags_make_vars", "get_make_env_vars")

def _empty_inputs():
    return struct(
        libs = [],
        include_dirs = [],
        headers = [],
    )

def _empty_tools():
    return struct(
        cc = "",
        cxx = "",
        cxx_linker_static = "",
        ld = "",
    )

def _quoted_flags():
    return struct(
        assemble = [],
        cc = ["-D__DATE__=\"redacted\""],
        cxx = ["-D__DATE__=\"redacted\""],
        cxx_linker_executable = [],
        cxx_linker_static = [],
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

def _make_env_vars_escape_dquotes_in_toolchain_flags_test(ctx):
    env = unittest.begin(ctx)

    result = get_make_env_vars("workspace", _empty_tools(), _quoted_flags(), {}, [], _empty_inputs(), False, [])

    asserts.equals(
        env,
        "CFLAGS=\"-D__DATE__=\\\\\\\"redacted\\\\\\\"\" CXXFLAGS=\"-D__DATE__=\\\\\\\"redacted\\\\\\\"\" RANLIB=\":\" LDFLAGS=\"\" CPPFLAGS=\"\"",
        result,
    )

    return unittest.end(env)

ldflags_vars_include_dynamic_modules_test = unittest.make(_ldflags_vars_include_dynamic_modules_test)
make_env_vars_escape_dquotes_in_toolchain_flags_test = unittest.make(_make_env_vars_escape_dquotes_in_toolchain_flags_test)
ldflags_vars_keep_link_categories_independent_test = unittest.make(_ldflags_vars_keep_link_categories_independent_test)
dynamic_module_link_flags_strip_darwin_library_flags_test = unittest.make(_dynamic_module_link_flags_strip_darwin_library_flags_test)
dynamic_module_link_flags_preserve_non_darwin_flags_test = unittest.make(_dynamic_module_link_flags_preserve_non_darwin_flags_test)

def make_env_vars_test_suite():
    unittest.suite(
        "make_env_vars_test_suite",
        partial.make(ldflags_vars_include_dynamic_modules_test, size = "small"),
        partial.make(ldflags_vars_keep_link_categories_independent_test, size = "small"),
        partial.make(dynamic_module_link_flags_strip_darwin_library_flags_test, size = "small"),
        partial.make(dynamic_module_link_flags_preserve_non_darwin_flags_test, size = "small"),
        partial.make(make_env_vars_escape_dquotes_in_toolchain_flags_test, size = "small"),
    )
