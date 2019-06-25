load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

cmake_external(
    name = "hello_world",
    binaries = select({
        "@bazel_tools//src/conditions:windows": ["CMakeHelloWorld.exe"],
        "@bazel_tools//src/conditions:darwin": ["CMakeHelloWorld"],
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
        "@bazel_tools//src/conditions:windows": "CMakeHelloWorld.exe",
        "@bazel_tools//src/conditions:darwin": "CMakeHelloWorld",
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
