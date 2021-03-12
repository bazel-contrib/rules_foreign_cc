load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "all_srcs",
    srcs = glob(["**"]),
)

cmake(
    name = "zlib",
    cmake_options = select({
        "@platforms//os:windows": ["-GNinja"],
        "//conditions:default": [],
    }),
    lib_source = ":all_srcs",
    make_commands = select({
        "@platforms//os:windows": [
            "ninja",
            "ninja install",
        ],
        "//conditions:default": [
            "make",
            "make install",
        ],
    }),
    out_static_libs = select({
        "@platforms//os:windows": ["zlibstatic.lib"],
        "//conditions:default": ["libz.a"],
    }),
)
