load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

# TODO: This should not be necessary but there appears to be some inconsistent
# behavior with the use of `constraint_value`s in `select` statements. A support
# thread was started at the end of https://github.com/bazelbuild/bazel/pull/12071
# Once it is possible to replace `:windows` with `@platforms//os:windows` that
# should be done for this file
config_setting(
    name = "windows",
    constraint_values = ["@platforms//os:windows"],
    visibility = ["//visibility:private"],
)

config_setting(
    name = "macos",
    constraint_values = ["@platforms//os:macos"],
    visibility = ["//visibility:private"],
)

cmake_external(
    name = "hello_world",
    binaries = select({
        ":windows": ["CMakeHelloWorld.exe"],
        ":macos": ["CMakeHelloWorld"],
        "//conditions:default": ["CMakeHelloWorld"],
    }),
    cmake_options = ["-GNinja"],
    generate_crosstool_file = True,
    lib_source = "@cmake_hello_world_variant_src//:all",
    make_commands = [
        "ninja",
        "ninja install",
    ],
)

filegroup(
    name = "binary",
    srcs = [":hello_world"],
    output_group = select({
        ":windows": "CMakeHelloWorld.exe",
        ":macos": "CMakeHelloWorld",
        "//conditions:default": "CMakeHelloWorld",
    }),
)

sh_test(
    name = "test_hello_world",
    srcs = ["test_hello_world.sh"],
    args = ["$(location binary)"],
    data = [":binary"],
    tags = ["windows"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
)
