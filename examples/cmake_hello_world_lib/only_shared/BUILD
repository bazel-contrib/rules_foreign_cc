# example code is taken from https://github.com/Akagi201/learning-cmake/tree/master/hello-world-lib
# for test only

filegroup(
    name = "srcs",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)

load("//tools/build_defs:cmake.bzl", "cmake_external")

cmake_external(
    name = "libhello",
    lib_source = ":srcs",
    shared_libraries = ["libhello.so"],
)

cc_binary(
    name = "run_libhello",
    srcs = ["hello_client.c"],
    deps = [":libhello"],
)

cc_test(
    name = "test_libhello",
    srcs = ["hello_client.c"],
    deps = [":libhello"],
)
