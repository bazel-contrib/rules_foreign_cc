"""Tests for bootstrap compiler flag transport."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//foreign_cc/built_tools/private:built_tools_framework.bzl", "split_system_include_flags")

def _forwarded_headers_test(ctx):
    env = unittest.begin(ctx)
    for forwarding in ["-Xclang", "-Xpreprocessor"]:
        for category in ["-internal-isystem", "-internal-externc-isystem"]:
            headers = [forwarding, category, forwarding, "relative/include"]
            flags = ["-O2"] + headers + ["-Xclang", "-fno-cxx-modules"]
            asserts.equals(env, (headers, ["-O2", "-Xclang", "-fno-cxx-modules"]), split_system_include_flags(flags))
    return unittest.end(env)

def _driver_headers_test(ctx):
    env = unittest.begin(ctx)
    headers = ["--sysroot=/sdk", "-isystem", "c/include", "-stdlib++-isystemcxx/include", "-stdlib++-isystem", "abi/include"]

    # Configure links through CC + CFLAGS + LDFLAGS; do not move its resource
    # directory into LD, where that invocation would lose compiler-rt libraries.
    remaining = ["-resource-dir=link/resources", "-resource-dir", "other/resources", "-Llib", "-lm"]
    asserts.equals(env, (headers, remaining), split_system_include_flags(headers + remaining))
    return unittest.end(env)

def _incomplete_forwarding_test(ctx):
    env = unittest.begin(ctx)
    for flags in [
        ["-Xclang", "-internal-isystem"],
        ["-Xpreprocessor", "-internal-externc-isystem", "-Xpreprocessor"],
        ["-Xclang", "-internal-isystem", "-Xpreprocessor", "path"],
    ]:
        asserts.equals(env, ([], flags), split_system_include_flags(flags))
    return unittest.end(env)

forwarded_headers_test = unittest.make(_forwarded_headers_test)
driver_headers_test = unittest.make(_driver_headers_test)
incomplete_forwarding_test = unittest.make(_incomplete_forwarding_test)

def built_tools_flags_test_suite():
    unittest.suite(
        "built_tools_flags_test_suite",
        forwarded_headers_test,
        driver_headers_test,
        incomplete_forwarding_test,
    )
