load("//tools/build_defs:cmake.bzl", "cmake_external")
load("@foreign_cc_platform_utils//:tools.bzl", "NINJA_COMMAND")

cmake_external(
    name = "cares",
    cache_entries = {
        "CARES_SHARED": "no",
        "CARES_STATIC": "on",
    },
    cmake_options = ["-GNinja"],
    lib_source = "@cares//:all",
    make_commands = [
        NINJA_COMMAND,
        NINJA_COMMAND + " install",
    ],
    static_libraries = ["libcares.a"],
    tools_deps = ["@foreign_cc_platform_utils//:ninja"],
)

cc_test(
    name = "test_c_ares",
    srcs = ["c-ares-test.cpp"],
    visibility = ["//:__pkg__"],
    deps = [":cares"],
)
