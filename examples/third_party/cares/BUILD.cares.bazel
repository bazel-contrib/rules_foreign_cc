load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "all_srcs",
    srcs = glob(["**"]),
)

cmake_external(
    name = "cares",
    cache_entries = {
        "CARES_SHARED": "no",
        "CARES_STATIC": "on",
    },
    cmake_options = ["-GNinja"],
    lib_source = ":all_srcs",
    make_commands = [
        # The correct path to the ninja tool is detected from the selected ninja_toolchain.
        # and "ninja" will be replaced with that path if needed
        "ninja",
        "ninja install",
    ],
    static_libraries = select({
        "@platforms//os:windows": ["cares.lib"],
        "//conditions:default": ["libcares.a"],
    }),
)
