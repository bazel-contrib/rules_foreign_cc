"""Helpers for the zlib producer/consumer matrix targets."""

load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake", "runnable_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

def zlib_linkage_test(name, expected_linkage, inspect_target, data):
    sh_test(
        name = name,
        size = "small",
        srcs = ["//zlib:verify_zlib_linkage.sh"],
        args = [
            expected_linkage,
            "$(rlocationpath {})".format(inspect_target),
        ],
        data = data + ["@bazel_tools//tools/bash/runfiles"],
    )

def zlib_runnable_test(name, runnable_target, data, runtime_library_pattern = ""):
    sh_test(
        name = name,
        size = "small",
        srcs = ["//zlib:run_runnable_binary.sh"],
        args = [
            "$(rlocationpath {})".format(runnable_target),
            runtime_library_pattern,
        ],
        data = data + [
            runnable_target,
            "@bazel_tools//tools/bash/runfiles",
        ],
    )

def zlib_cmake_consumer(
        name,
        deps = [],
        dynamic_deps = [],
        cache_entries = {},
        expected_linkage = "static",
        runnable = False,
        runnable_library_pattern = "",
        lib_source = "//zlib:cmake_usage_srcs"):
    """Build a foreign CMake consumer and attach linkage and optional runnable tests.

    Args:
      name: Target name for the foreign consumer.
      deps: Normal dependency edges passed to the foreign rule.
      dynamic_deps: Shared-library dependencies passed via dynamic_deps.
      cache_entries: Extra CMake cache entries for the consumer.
      expected_linkage: Whether the produced binary should link zlib statically or dynamically.
      runnable: Whether to add a separate runnable_binary-based runtime test.
      runnable_library_pattern: Regex that should match the loader output for the staged zlib library.
      lib_source: CMake consumer source tree for the foreign rule.
    """
    cmake(
        name = name,
        cache_entries = dict(cache_entries, CMAKE_VERBOSE_MAKEFILE = "ON"),
        deps = deps,
        dynamic_deps = dynamic_deps,
        lib_source = lib_source,
        out_include_dir = "",
        out_binaries = select({
            "@platforms//os:windows": ["zlib-example.exe"],
            "//conditions:default": ["zlib-example"],
        }),
    )

    native.filegroup(
        name = name + "_binary",
        srcs = [":" + name],
        output_group = select({
            "@platforms//os:windows": "zlib-example.exe",
            "//conditions:default": "zlib-example",
        }),
    )

    zlib_linkage_test(
        name = name + "_test",
        expected_linkage = expected_linkage,
        inspect_target = ":" + name + "_binary",
        data = [
            ":" + name,
            ":" + name + "_binary",
        ],
    )

    if runnable:
        runnable_binary(
            name = name + "_run",
            binary = "zlib-example",
            foreign_cc_target = ":" + name,
        )

        zlib_runnable_test(
            name = name + "_run_test",
            runnable_target = ":" + name + "_run",
            data = [
                ":" + name,
            ],
            runtime_library_pattern = runnable_library_pattern,
        )
