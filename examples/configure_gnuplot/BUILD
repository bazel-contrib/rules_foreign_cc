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
    defines = ["HAVE_LIBPNG"],
    lib_source = "@libgd//:all",
    deps = [
        ":freetype",
        ":libpng",
    ],
)

cc_binary(
    name = "zlib_usage_example",
    srcs = ["zlib-example.cpp"],
    deps = [":libz"],
)

cc_binary(
    name = "libpng_usage_example",
    srcs = ["libpng_usage_example.cpp"],
    deps = [
        ":libpng",
    ],
)

cc_binary(
    name = "test_libgd_with_png",
    srcs = ["arc.c"],
    deps = ["libgd"],
)
