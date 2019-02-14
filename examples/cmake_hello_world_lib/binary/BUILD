# example code is taken from https://github.com/Akagi201/learning-cmake/tree/master/hello-world-lib
# for test only
load("@bazel_tools//tools/build_rules:test_rules.bzl", "file_test")

filegroup(
    name = "srcs",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)

load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

cmake_external(
    name = "libhello",
    binaries = select({
        "@bazel_tools//src/conditions:windows": ["hello.exe"],
        "@bazel_tools//src/conditions:darwin": ["hello"],
        "//conditions:default": ["hello"],
    }),
    # Probably this variable should be set by default.
    # Apparently, it needs to be set for shared libraries on Mac OS
    cache_entries = {
        "CMAKE_MACOSX_RPATH": "True",
    },
    lib_source = ":srcs",
)

filegroup(
    name = "binary",
    srcs = [":libhello"],
    output_group = "hello",
)

genrule(
    name = "call_hello",
    srcs = [],
    outs = ["out.txt"],
    cmd = "./$(location binary) me > $(location out.txt)",
    tools = [":binary"],
)

file_test(
    name = "test_binary",
    content = "Hello, me!",
    file = ":call_hello",
)
