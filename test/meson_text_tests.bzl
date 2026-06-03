"""Unit tests for Meson script helpers."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//foreign_cc:meson.bzl", "export_for_test")

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

join_flags_list_escapes_loader_tokens_for_shell_test = unittest.make(_join_flags_list_escapes_loader_tokens_for_shell_test)
join_flags_list_preserves_escaped_loader_tokens_for_shell_test = unittest.make(_join_flags_list_preserves_escaped_loader_tokens_for_shell_test)

def meson_text_test_suite():
    unittest.suite(
        "meson_text_test_suite",
        partial.make(join_flags_list_escapes_loader_tokens_for_shell_test, size = "small"),
        partial.make(join_flags_list_preserves_escaped_loader_tokens_for_shell_test, size = "small"),
    )
