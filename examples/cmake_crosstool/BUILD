load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

filegroup(
    name = "srcs",
    srcs = glob(["**"]),
    visibility = ["//src/test/shell/bazel/testdata:__pkg__"],
)

cc_binary(
    name = "hello",
    srcs = ["hello.cc"],
)

cmake_external(
    name = "hello_cmake",
    lib_source = "//static:srcs",
    out_include_dir = "include/version123",
)
