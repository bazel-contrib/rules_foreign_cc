"""Unit tests for make environment variable rendering."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:make_env_vars.bzl", "get_ldflags_make_vars", "get_make_env_vars")

def _tools():
    return struct(
        cc = "",
        cxx = "",
        cxx_linker_static = "",
        ld = "",
    )

def _flags():
    return struct(
        assemble = [],
        cc = [],
        cxx = [],
        cxx_linker_executable = [
            "-Wl,-rpath,$ORIGIN/lib",
            "-Wl,-rpath,$EXEC_ORIGIN/bin",
        ],
        cxx_linker_static = [],
    )

def _escaped_flags():
    return struct(
        assemble = [],
        cc = [],
        cxx = [],
        cxx_linker_executable = [
            "-Wl,-rpath,\\$ORIGIN/lib",
            "-Wl,-rpath,\\$EXEC_ORIGIN/bin",
        ],
        cxx_linker_static = [],
    )

def _inputs():
    return struct(
        headers = [],
        include_dirs = [],
        libs = [],
    )

def _get_make_env_vars_escapes_loader_tokens_for_shell_test(ctx):
    env = unittest.begin(ctx)

    result = get_make_env_vars("workspace", _tools(), _flags(), {}, [], _inputs(), False, [])

    asserts.equals(
        env,
        "LDFLAGS=\"-Wl,-rpath,\\$ORIGIN/lib -Wl,-rpath,\\$EXEC_ORIGIN/bin\" RANLIB=\":\" CPPFLAGS=\"\"",
        result,
    )

    return unittest.end(env)

def _get_make_env_vars_preserves_escaped_loader_tokens_for_shell_test(ctx):
    env = unittest.begin(ctx)

    result = get_make_env_vars("workspace", _tools(), _escaped_flags(), {}, [], _inputs(), False, [])

    asserts.equals(
        env,
        "LDFLAGS=\"-Wl,-rpath,\\$ORIGIN/lib -Wl,-rpath,\\$EXEC_ORIGIN/bin\" RANLIB=\":\" CPPFLAGS=\"\"",
        result,
    )

    return unittest.end(env)

def _get_make_env_vars_make_context_escapes_loader_tokens_for_make_test(ctx):
    env = unittest.begin(ctx)

    result = get_make_env_vars(
        "workspace",
        _tools(),
        _flags(),
        {},
        [],
        _inputs(),
        False,
        [],
        expansion_context = "make",
    )

    asserts.equals(
        env,
        "LDFLAGS=\"-Wl,-rpath,\\\\$\\$ORIGIN/lib -Wl,-rpath,\\\\$\\$EXEC_ORIGIN/bin\" RANLIB=\":\" CPPFLAGS=\"\"",
        result,
    )

    return unittest.end(env)

def _get_make_env_vars_make_context_preserves_escaped_loader_tokens_test(ctx):
    env = unittest.begin(ctx)

    result = get_make_env_vars(
        "workspace",
        _tools(),
        _escaped_flags(),
        {},
        [],
        _inputs(),
        False,
        [],
        expansion_context = "make",
    )

    asserts.equals(
        env,
        "LDFLAGS=\"-Wl,-rpath,\\$ORIGIN/lib -Wl,-rpath,\\$EXEC_ORIGIN/bin\" RANLIB=\":\" CPPFLAGS=\"\"",
        result,
    )

    return unittest.end(env)

def _get_ldflags_make_vars_escapes_loader_tokens_for_make_test(ctx):
    env = unittest.begin(ctx)

    result = get_ldflags_make_vars(["LDFLAGS"], [], "workspace", _flags(), {}, [], _inputs(), False)

    asserts.equals(
        env,
        "LDFLAGS=\"-Wl,-rpath,\\\\$\\$ORIGIN/lib -Wl,-rpath,\\\\$\\$EXEC_ORIGIN/bin\"",
        result,
    )

    return unittest.end(env)

def _get_ldflags_make_vars_preserves_escaped_loader_tokens_for_make_test(ctx):
    env = unittest.begin(ctx)

    result = get_ldflags_make_vars(["LDFLAGS"], [], "workspace", _escaped_flags(), {}, [], _inputs(), False)

    asserts.equals(
        env,
        "LDFLAGS=\"-Wl,-rpath,\\$ORIGIN/lib -Wl,-rpath,\\$EXEC_ORIGIN/bin\"",
        result,
    )

    return unittest.end(env)

get_make_env_vars_escapes_loader_tokens_for_shell_test = unittest.make(_get_make_env_vars_escapes_loader_tokens_for_shell_test)
get_make_env_vars_preserves_escaped_loader_tokens_for_shell_test = unittest.make(_get_make_env_vars_preserves_escaped_loader_tokens_for_shell_test)
get_make_env_vars_make_context_escapes_loader_tokens_for_make_test = unittest.make(_get_make_env_vars_make_context_escapes_loader_tokens_for_make_test)
get_make_env_vars_make_context_preserves_escaped_loader_tokens_test = unittest.make(_get_make_env_vars_make_context_preserves_escaped_loader_tokens_test)
get_ldflags_make_vars_escapes_loader_tokens_for_make_test = unittest.make(_get_ldflags_make_vars_escapes_loader_tokens_for_make_test)
get_ldflags_make_vars_preserves_escaped_loader_tokens_for_make_test = unittest.make(_get_ldflags_make_vars_preserves_escaped_loader_tokens_for_make_test)

def make_env_vars_test_suite():
    unittest.suite(
        "make_env_vars_test_suite",
        partial.make(get_make_env_vars_escapes_loader_tokens_for_shell_test, size = "small"),
        partial.make(get_make_env_vars_preserves_escaped_loader_tokens_for_shell_test, size = "small"),
        partial.make(get_make_env_vars_make_context_escapes_loader_tokens_for_make_test, size = "small"),
        partial.make(get_make_env_vars_make_context_preserves_escaped_loader_tokens_test, size = "small"),
        partial.make(get_ldflags_make_vars_escapes_loader_tokens_for_make_test, size = "small"),
        partial.make(get_ldflags_make_vars_preserves_escaped_loader_tokens_for_make_test, size = "small"),
    )
