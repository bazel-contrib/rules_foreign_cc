# example code is taken from https://github.com/Akagi201/learning-cmake/tree/master/hello-world-lib
# for test only

filegroup(
    name = "srcs",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"]
)

load("//tools/build_defs:cmake.bzl", "cmake_external")
cmake_external(
    name = "libhello",
    lib_source = ":srcs",
    # pass include/version123 to C/C++ provider as include directory
    out_include_dir = "include/version123"
)

cc_binary(
    name = "libhello_example",
    # includes just hello.h, include directory: "include/version123"
    srcs = ["hello_client.c"],
    deps = [":libhello"]
)

cmake_external(
    name = "libhello123",
    lib_source = ":srcs",
    out_include_dir = "include",
    # the name of the static library != <name>.a, put it explicitly
    static_libraries = ["libhello.a"]
)
cc_binary(
    name = "libhello_example123",
    # includes version123/hello.h, include directory: "include"
    srcs = ["hello_client_version123.c"],
    deps = [":libhello123"]
)
