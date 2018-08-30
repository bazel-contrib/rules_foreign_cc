load("//tools/build_defs:cmake.bzl", "cmake_external")
load("@foreign_cc_platform_utils//:tools.bzl", "NINJA_COMMAND")

cmake_external(
    name = "nghttp2",
    cache_entries = {
        "ENABLE_STATIC_LIB": "on",
        "ENABLE_LIB_ONLY": "on",
    },
    cmake_options = ["-GNinja"],
    lib_source = "@nghttp2//:all",
    make_commands = [
        NINJA_COMMAND,
        NINJA_COMMAND + " install",
    ],
    static_libraries = ["libnghttp2.a"],
    tools_deps = ["@foreign_cc_platform_utils//:ninja"],
)

cc_test(
    name = "test_nghttp2",
    srcs = ["nghttp2-test.cpp"],
    visibility = ["//:__pkg__"],
    deps = [":nghttp2"],
)
