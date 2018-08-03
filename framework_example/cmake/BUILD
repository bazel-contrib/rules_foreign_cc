load("//tools/build_defs:cmake.bzl", "cmake_external")

cmake_external(
    name = "libz",
    lib_source = "@zlib//:all",
)

cmake_external(
    name = "libpng",
    lib_source = "@libpng//:all",
    out_include_dir = "include/libpng16",
    static_libraries = ["libpng16.a"],
    deps = [":libz"],
)

cc_binary(
    name = "libpng_test",
    srcs = ["libpng_test.cpp"],
    args = ["$(location bazel-icon-transparent.png) out.png"],
    data = ["bazel-icon-transparent.png"],
    deps = [
        ":libpng",
        ":libz",
    ],
)

cc_binary(
    name = "zlib_usage_example",
    srcs = ["zlib-example.cpp"],
    deps = [":libz"],
)
