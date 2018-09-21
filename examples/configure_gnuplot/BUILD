load("//tools/build_defs:configure.bzl", "configure_make")

configure_make(
    name = "libz",
    lib_source = "@zlib//:all",
)

configure_make(
    name = "libpng",
    lib_source = "@libpng//:all",
    out_include_dir = "include/libpng16",
    static_libraries = ["libpng16.a"],
    deps = [":libz"],
)

configure_make(
    name = "freetype",
    lib_source = "@freetype//:all",
    out_include_dir = "include/freetype2",
    static_libraries = ["libfreetype.a"],
    deps = [
        ":libpng",
        ":libz",
    ],
)

configure_make(
    name = "libgd",
    configure_options = [
        "--with-png",
        "--with-freetype",
        "--with-zlib",
    ],
    lib_source = "@libgd//:all",
    deps = [
        ":freetype",
        ":libpng",
        ":libz",
    ],
)

cc_test(
    name = "test_zlib",
    srcs = ["zlib-example.cpp"],
    deps = [":libz"],
)

cc_test(
    name = "test_libpng",
    srcs = ["libpng_usage_example.cpp"],
    args = ["$(location bazel-icon-transparent.png) out.png"],
    data = ["bazel-icon-transparent.png"],
    deps = [
        ":libpng",
    ],
)

cc_test(
    name = "test_libgd",
    srcs = ["arc.c"],
    deps = [":libgd"],
)

test_suite(
    name = "configure_libgd_tests",
    tests = [
        ":test_libgd",
        ":test_libpng",
        ":test_zlib",
    ],
)
