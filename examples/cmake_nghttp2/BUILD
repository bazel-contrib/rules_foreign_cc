load("//tools/build_defs:cmake.bzl", "cmake_external")
load("//tools/build_defs:ninja_build.bzl", "ninja_tool")

ninja_tool(
    name = "ninjatool",
    ninja_srcs = "@ninja_build//:all",
)

cmake_external(
    name = "nghttp2",
    cache_entries = {
        "ENABLE_STATIC_LIB": "on",
        "ENABLE_LIB_ONLY": "on",
    },
    cmake_options = ["-GNinja"],
    lib_source = "@nghttp2//:all",
    make_commands = [
        "ninja",
        "ninja install",
    ],
    static_libraries = ["libnghttp2.a"],
    tools_deps = [":ninjatool"],
)

cc_test(
    name = "test_nghttp2",
    srcs = ["nghttp2-test.cpp"],
    visibility = ["//:__pkg__"],
    deps = [":nghttp2"],
)
