"""Unit tests for `.x` wildcard version resolution in the bzlmod planner."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:extension_impl.bzl", "resolve_version")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:tool_specs.bzl", "get_spec")

def _resolve_version_test(ctx):
    env = unittest.begin(ctx)

    # A known wildcard resolves to the tool's latest patch for that minor.
    # Hard-code the expected patch so the assertion fails if the map ever
    # misresolves, rather than reading the same dict key on both sides.
    cmake = get_spec("cmake")
    asserts.equals(env, "3.31.12", resolve_version("cmake", "3.31.x"))
    asserts.true(
        env,
        "3.31.12" in cmake.known_versions,
        "wildcard target must be an exact known version",
    )

    # An exact version passes through untouched.
    asserts.equals(env, "3.31.12", resolve_version("cmake", "3.31.12"))

    # The empty string (no version) passes through.
    asserts.equals(env, "", resolve_version("cmake", ""))

    # An unknown wildcard passes through unchanged so validate_tag can reject
    # it with a clear message.
    asserts.equals(env, "3.99.x", resolve_version("cmake", "3.99.x"))

    # ninja wildcards resolve too.
    asserts.equals(env, "1.13.2", resolve_version("ninja", "1.13.x"))

    # make ships irregular versions: two-component 4.3/4.4 plus 4.4.1. All
    # three are exact, known, fetchable versions, and the 4.4.x wildcard
    # resolves to the latest patch in the series (4.4.1), matching what the
    # old WORKSPACE built_toolchains.bzl accepted.
    make = get_spec("make")
    for v in ["4.3", "4.4", "4.4.1"]:
        asserts.true(
            env,
            v in make.known_versions,
            "make version {} should be reachable".format(v),
        )
    asserts.equals(env, "4.4.1", resolve_version("make", "4.4.x"))
    asserts.equals(env, "4.3", resolve_version("make", "4.3.x"))

    return unittest.end(env)

def _known_versions_are_exact_test(ctx):
    env = unittest.begin(ctx)

    # known_versions must never contain a `.x` key -- those live only in the
    # wildcards map. The source dicts carry duplicate `.x` keys, so this
    # guards against them leaking into known_versions.
    for tool in ["cmake", "ninja", "make", "meson", "pkgconfig"]:
        spec = get_spec(tool)
        for v in spec.known_versions:
            asserts.false(
                env,
                v.endswith(".x"),
                "known_versions for {} leaked a wildcard key: {}".format(tool, v),
            )

        # Every wildcard must point at an exact known version.
        for key, target in spec.wildcards.items():
            asserts.true(env, key.endswith(".x"), "wildcard key not a .x: " + key)
            asserts.true(
                env,
                target in spec.known_versions,
                "wildcard {} -> {} not in known_versions".format(key, target),
            )

    return unittest.end(env)

resolve_version_test = unittest.make(_resolve_version_test)
known_versions_are_exact_test = unittest.make(_known_versions_are_exact_test)

def wildcard_resolution_test_suite():
    unittest.suite(
        "wildcard_resolution_test_suite",
        partial.make(resolve_version_test, size = "small"),
        partial.make(known_versions_are_exact_test, size = "small"),
    )
