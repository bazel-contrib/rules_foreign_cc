load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")
load("@foreign_cc_platform_utils//:tools.bzl", "NINJA_COMMAND", "NINJA_DEP")

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
    tools_deps = NINJA_DEP,
)

cc_test(
    name = "test_c_ares",
    srcs = ["c-ares-test.cpp"],
    visibility = ["//:__pkg__"],
    deps = [":cares"],
)
