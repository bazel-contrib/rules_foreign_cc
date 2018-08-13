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
    postfix_script = "echo \"POST\""
)

cc_binary(
    name = "libpng_usage_example",
    srcs = ["libpng_usage_example.cpp"],
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

sh_test(
    name = "test_zlib",
    srcs = ["test_zlib.sh"],
    data = [":zlib_usage_example"],
    visibility = ["//:__pkg__"]
)

sh_test(
    name = "test_libpng",
    srcs = ["test_libpng.sh"],
    data = [":libpng_usage_example", "bazel-icon-transparent.png",],
    args = ["$(location bazel-icon-transparent.png) out.png"],
    visibility = ["//:__pkg__"]
)