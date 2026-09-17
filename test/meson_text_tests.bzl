"""Unit tests for meson script creation."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//foreign_cc:meson.bzl", "export_for_test")

def _list_to_str_repr_test(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, "['a']", export_for_test.list_to_str_repr(["a"]))
    asserts.equals(env, "['a', 'b']", export_for_test.list_to_str_repr(["a", "b"]))
    asserts.equals(env, "[]", export_for_test.list_to_str_repr([]))

    # Flags with commas must be quoted so meson treats them as single array elements.
    asserts.equals(env, "['a,b', 'c,d']", export_for_test.list_to_str_repr(["a,b", "c,d"]))

    # Flags that look like linker options are passed through unchanged.
    asserts.equals(
        env,
        "['--sysroot=/some/path', '-fuse-ld=lld']",
        export_for_test.list_to_str_repr(["--sysroot=/some/path", "-fuse-ld=lld"]),
    )

    return unittest.end(env)

def _join_flags_list_escapes_loader_tokens_for_shell_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.join_flags_list("ws", [
        "-Wl,-rpath,$ORIGIN/lib",
        "-Wl,-rpath,$EXEC_ORIGIN/bin",
    ])

    asserts.equals(
        env,
        "-Wl,-rpath,\\$ORIGIN/lib -Wl,-rpath,\\$EXEC_ORIGIN/bin",
        result,
    )

    return unittest.end(env)

def _join_flags_list_preserves_escaped_loader_tokens_for_shell_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.join_flags_list("ws", [
        "-Wl,-rpath,\\$ORIGIN/lib",
        "-Wl,-rpath,\\$EXEC_ORIGIN/bin",
    ])

    asserts.equals(
        env,
        "-Wl,-rpath,\\$ORIGIN/lib -Wl,-rpath,\\$EXEC_ORIGIN/bin",
        result,
    )

    return unittest.end(env)

list_to_str_repr_test = unittest.make(_list_to_str_repr_test)
join_flags_list_escapes_loader_tokens_for_shell_test = unittest.make(_join_flags_list_escapes_loader_tokens_for_shell_test)
join_flags_list_preserves_escaped_loader_tokens_for_shell_test = unittest.make(_join_flags_list_preserves_escaped_loader_tokens_for_shell_test)

def meson_script_test_suite():
    unittest.suite(
        "meson_script_test_suite",
        partial.make(list_to_str_repr_test, size = "small"),
        partial.make(join_flags_list_escapes_loader_tokens_for_shell_test, size = "small"),
        partial.make(join_flags_list_preserves_escaped_loader_tokens_for_shell_test, size = "small"),
    )
