"""Unit tests for tool version wildcard resolution."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(":cmake_versions.bzl", "CMAKE_SRCS")

def _cmake_wildcard_keys_test_impl(ctx):
    env = unittest.begin(ctx)

    # A representative kept series exposes both the exact-latest and wildcard.
    asserts.true(env, "3.19.x" in CMAKE_SRCS, "expected 3.19.x wildcard key")
    asserts.true(env, "3.19.8" in CMAKE_SRCS, "expected 3.19.8 exact key")

    # Wildcard and exact-latest point at the same entry.
    asserts.equals(env, CMAKE_SRCS["3.19.8"], CMAKE_SRCS["3.19.x"])

    # A dropped non-latest patch is absent (hard-fail at lookup time).
    asserts.false(env, "3.19.4" in CMAKE_SRCS, "3.19.4 should be dropped")

    return unittest.end(env)

cmake_wildcard_keys_test = unittest.make(_cmake_wildcard_keys_test_impl)

def version_resolution_test_suite(name):
    unittest.suite(
        name,
        cmake_wildcard_keys_test,
    )
