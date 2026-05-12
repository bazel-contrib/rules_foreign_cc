"""Helpers for runtime search path integration tests."""

load("@rules_shell//shell:sh_test.bzl", "sh_test")

def runtime_search_paths_test(name, target):
    sh_test(
        name = name,
        size = "small",
        srcs = ["runtime_search_paths_test.sh"],
        data = [
            target,
            "@bazel_tools//tools/bash/runfiles",
        ],
        env = {
            "FILES": "$(rlocationpaths %s)" % target,
        },
        target_compatible_with = select({
            "@platforms//os:linux": [],
            "@platforms//os:macos": [],
            "//conditions:default": ["@platforms//:incompatible"],
        }),
    )
