load("@rules_foreign_cc//tools/build_defs:configure.bzl", "configure_make")
load("@bazel_tools//tools/build_rules:test_rules.bzl", "file_test")

configure_make(
    name = "libz",
    lib_source = "@zlib//:all",
)

configure_make(
    name = "libpng",
    configure_options = [
        "--with-zlib=\"$$EXT_BUILD_DEPS$$/libz\"",
    ],
    lib_source = "@libpng//:all",
    out_include_dir = "include/libpng16",
    static_libraries = ["libpng16.a"],
    deps = [":libz"],
)

configure_make(
    name = "freetype",
    configure_options = [
        "--with-png=\"$$EXT_BUILD_DEPS$$/libpng\"",
        "--with-zlib=\"$$EXT_BUILD_DEPS$$/libz\"",
    ],
    lib_source = "@freetype//:all",
    out_include_dir = "include/freetype2",
    static_libraries = ["libfreetype.a"],
    deps = [
        ":libpng",
        ":libz",
    ],
)

libgd_name = select({
    "@bazel_tools//src/conditions:windows": ["libgd.lib"],
    "//conditions:default": ["libgd.a"],
})

configure_make(
    name = "libgd",
    binaries = [
        "webpng",
        "gdtopng",
    ],
    configure_options = [
        "--disable-shared",
        "--with-png=\"$$EXT_BUILD_DEPS$$/libpng\"",
        "--with-freetype=\"$$EXT_BUILD_DEPS$$/freetype\"",
        "--with-zlib=\"$$EXT_BUILD_DEPS$$/libz\"",
    ],
    lib_source = "@libgd//:all",
    static_libraries = libgd_name,
    deps = [
        ":freetype",
        ":libpng",
        ":libz",
    ],
)

filegroup(
    name = "gdtopng_fg",
    srcs = [":libgd"],
    output_group = "gdtopng",
)

genrule(
    name = "invoke_gdtopng",
    srcs = [],
    outs = ["out.txt"],
    cmd = "./$(location gdtopng_fg) > $(location out.txt) 2>&1 || true",
    tools = [":gdtopng_fg"],
)

file_test(
    name = "test_gdtopng",
    content = "Usage: gdtopng filename.gd filename.png\n",
    file = ":invoke_gdtopng",
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
