load("//tools/build_defs:cmake.bzl", "cmake_external")

cmake_external(
    name = "libz",
    lib_source = "@zlib//:all",
)

cc_binary(
    name = "test_zlib",
    srcs = ["zlib-example.cpp"],
    deps = ["libz"],
)
