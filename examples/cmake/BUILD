load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

cmake_external(
    name = "libz",
    cache_entries = {
        # fictive prefix to test prefix merging
        "CMAKE_PREFIX_PATH": "/bac/def",
    },
    lib_source = "@zlib//:all",
)

cmake_external(
    name = "libpng",
    cache_entries = {
        "ZLIB_ROOT": "$EXT_BUILD_DEPS/libz",
    },
    lib_source = "@libpng//:all",
    out_include_dir = "include/libpng16",
    static_libraries = ["libpng16.a"],
    deps = [":libz"],
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
    visibility = ["//:__pkg__"],
)

sh_test(
    name = "test_libpng",
    srcs = ["test_libpng.sh"],
    args = ["$(location bazel-icon-transparent.png) out.png"],
    data = [
        "bazel-icon-transparent.png",
        ":libpng_usage_example",
    ],
    visibility = ["//:__pkg__"],
)

cmake_external(
    name = "freetype",
    cache_entries = {
        "ZLIB_ROOT": "$EXT_BUILD_DEPS/libz",
        "PNG_LIBRARY": "$EXT_BUILD_DEPS/libpng/lib/libpng16.a",
        "PNG_PNG_INCLUDE_DIR": "$EXT_BUILD_DEPS/libpng/include",
    },
    lib_source = "@freetype//:all",
    out_include_dir = "include/freetype2",
    static_libraries = ["libfreetype.a"],
    deps = [
        ":libpng",
        ":libz",
    ],
)

cmake_external(
    name = "libgd",
    cache_entries = {
        "BUILD_SHARED_LIBS": "OFF",
        "BUILD_STATIC_LIBS": "ON",
        "ENABLE_PNG": "1",
        "ENABLE_FREETYPE": "1",
        "ZLIB_ROOT": "$EXT_BUILD_DEPS/libz",
        "PNG_LIBRARY": "$EXT_BUILD_DEPS/libpng/lib/libpng16.a",
        "PNG_PNG_INCLUDE_DIR": "$EXT_BUILD_DEPS/libpng/include",
        "FREETYPE_LIBRARY": "$EXT_BUILD_DEPS/freetype/lib/libfreetype.a",
        "FREETYPE_INCLUDE_DIRS": "$EXT_BUILD_DEPS/freetype/include/freetype2",
    },
    defines = ["HAVE_LIBPNG"],
    lib_source = "@libgd//:all",
    deps = [
        ":freetype",
        ":libpng",
        ":libz",
    ],
)

cc_binary(
    name = "libgd_with_png_example",
    srcs = ["arc.c"],
    deps = [
        ":libgd",
    ],
)

sh_test(
    name = "test_libgd",
    srcs = ["test_libgd.sh"],
    data = [
        ":libgd_with_png_example",
    ],
    visibility = ["//:__pkg__"],
)
