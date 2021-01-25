load("@rules_cc//cc:defs.bzl", "cc_test")
load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

cmake_external(
    name = "old_cares",
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
        # The correct path to the ninja tool is detected from the selected ninja_toolchain.
        # and "ninja" will be replaced with that path if needed
        "ninja",
        "ninja install",
    ],
    static_libraries = ["libcares.a"],
)

cc_test(
    name = "test_old_c_ares",
    srcs = ["c-ares-test.cpp"],
    visibility = ["//:__pkg__"],
    deps = [":old_cares"],
)

cc_test(
    name = "test_c_ares",
    srcs = ["c-ares-test.cpp"],
    visibility = ["//:__pkg__"],
    deps = [":cares"],
)
