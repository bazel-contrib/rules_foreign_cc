# example code is taken from https://github.com/Akagi201/learning-cmake/tree/master/hello-world-lib
# for test only

load("@rules_cc//cc:defs.bzl", "cc_test")
load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

filegroup(
    name = "srcs",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)

cmake_external(
    name = "libhello",
    # Probably this variable should be set by default.
    # Apparently, it needs to be set for shared libraries on Mac OS
    cache_entries = {
        "CMAKE_MACOSX_RPATH": "True",
    },
    lib_source = ":srcs",
    shared_libraries = select({
        "@platforms//os:windows": ["libhello.dll"],
        "@platforms//os:macos": ["libhello.dylib"],
        "//conditions:default": ["libhello.so"],
    }),
)

cc_test(
    name = "test_libhello",
    srcs = ["hello_client.c"],
    deps = [":libhello"],
)
