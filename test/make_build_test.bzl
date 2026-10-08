"""Unit tests for the GNU Make bootstrap archiver flags."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//foreign_cc/built_tools:make_build.bzl", "export_for_test")

def _make_arflags_test(ctx):
    env = unittest.begin(ctx)

    flags = ["-static"]
    for ar in ["libtool", "/usr/bin/libtool", "llvm-libtool-darwin", "/opt/llvm/bin/llvm-libtool-darwin"]:
        asserts.equals(env, ["-static", "-o"], export_for_test.make_arflags(ar, flags))

    for ar in ["ar", "/usr/bin/ar", "llvm-ar", "/opt/llvm/bin/llvm-ar"]:
        asserts.equals(env, ["-static"], export_for_test.make_arflags(ar, flags))

    # Toolchain flags may be frozen and must not be modified in place.
    asserts.equals(env, ["-static"], flags)

    return unittest.end(env)

make_arflags_test = unittest.make(_make_arflags_test)

def make_build_test_suite():
    unittest.suite(
        "make_build_test_suite",
        partial.make(make_arflags_test, size = "small"),
    )
