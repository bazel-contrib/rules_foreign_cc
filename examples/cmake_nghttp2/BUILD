load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

cmake_external(
    name = "nghttp2",
    cache_entries = {
        "ENABLE_STATIC_LIB": "on",
        "ENABLE_LIB_ONLY": "on",
    },
    cmake_options = ["-GNinja"],
    lib_source = "@nghttp2//:all",
    make_commands = [
        # The correct path to the ninja tool is detected from the selected ninja_toolchain.
        # and "ninja" will be replaced with that path if needed
        "ninja",
        "ninja install",
    ],
    static_libraries = ["libnghttp2.a"],
)

cc_test(
    name = "test_nghttp2",
    srcs = ["nghttp2-test.cpp"],
    visibility = ["//:__pkg__"],
    deps = [":nghttp2"],
)
