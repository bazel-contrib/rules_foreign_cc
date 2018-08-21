load("//tools/build_defs:cmake.bzl", "cmake_external")
load("//tools/build_defs:ninja_build.bzl", "ninja_tool")

ninja_tool(
    name = "ninjatool",
    ninja_srcs = "@ninja_build//:all",
)

sh_library(
    name = "ninja",
    srcs = [":ninjatool"],
)

cmake_external(
    name = "cares",
    cache_entries = {
        "CARES_SHARED": "no",
        "CARES_STATIC": "on",
    },
    cmake_options = ["-GNinja"],
    lib_source = "@cares//:all",
    make_commands = [
        "ninja",
        "ninja install",
    ],
    static_libraries = ["libcares.a"],
    tools_deps = [":ninjatool"],
)

cc_test(
    name = "test_c_ares",
    srcs = ["c-ares-test.cpp"],
    visibility = ["//:__pkg__"],
    deps = [":cares"],
)
