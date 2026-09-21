"""Test macros for the runtime library search directory integration fixture."""

load("@rules_shell//shell:sh_test.bzl", "sh_test")

def runtime_search_test(name, family, target):
    """Runs the installed binary with the dynamic loader env cleared.

    Asserts the runtime_app binary built by `target` loads its shared-library
    chain purely through baked-in runtime search paths (rpaths), with
    LD_LIBRARY_PATH/DYLD_LIBRARY_PATH unset.

    Args:
      name: Test target name.
      family: Rule-family marker the binary prints (e.g. "cmake", "make").
      target: foreign_cc target producing the runtime_app binary.
    """
    sh_test(
        name = name,
        size = "small",
        srcs = ["runtime_search_test.sh"],
        args = [
            family,
            "$(rlocationpaths %s)" % target,
        ],
        data = [
            target,
            "@bazel_tools//tools/bash/runfiles",
        ],
        target_compatible_with = select({
            "@platforms//os:linux": [],
            "@platforms//os:macos": [],
            "//conditions:default": ["@platforms//:incompatible"],
        }),
    )

def runtime_search_paths_test(
        name,
        target,
        expected_additional_binary_runtime_paths = [],
        expected_additional_library_runtime_paths = []):
    sh_test(
        name = name,
        size = "small",
        srcs = ["runtime_search_paths_test.sh"],
        data = [
            target,
            "@bazel_tools//tools/bash/runfiles",
        ],
        env = {
            # Loader-relative paths (no $ORIGIN/@loader_path prefix); the test
            # script prepends the per-OS loader token and asserts each one is
            # present in addition to the baseline paths (membership, not the
            # full set). Binary paths are checked against runtime_app, library
            # paths against libmiddle, mirroring the executable-vs-dynamic origin
            # split.
            "EXPECTED_ADDITIONAL_BINARY_RUNTIME_PATHS": " ".join(expected_additional_binary_runtime_paths),
            "EXPECTED_ADDITIONAL_LIBRARY_RUNTIME_PATHS": " ".join(expected_additional_library_runtime_paths),
            "FILES": "$(rlocationpaths %s)" % target,
        },
        target_compatible_with = select({
            "@platforms//os:linux": [],
            "@platforms//os:macos": [],
            "//conditions:default": ["@platforms//:incompatible"],
        }),
    )
