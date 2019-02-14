# example code is taken from https://github.com/Akagi201/learning-cmake/tree/master/hello-world-lib
# for test only

filegroup(
    name = "srcs",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)

load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

cmake_external(
    name = "libhello",
    # Probably this variable should be set by default.
    # Apparently, it needs to be set for shared libraries on Mac OS
    cache_entries = {
        "CMAKE_MACOSX_RPATH": "True",
    },
    lib_source = ":srcs",
    shared_libraries = select({
        "@bazel_tools//src/conditions:windows": ["libhello.dll"],
        "@bazel_tools//src/conditions:darwin": ["libhello.dylib"],
        "//conditions:default": ["libhello.so"],
    }),
)

cc_test(
    name = "test_libhello",
    srcs = ["hello_client.c"],
    deps = [":libhello"],
)
