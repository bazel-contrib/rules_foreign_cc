"""libiconv is only expected to be used on MacOS systems"""

load("@rules_foreign_cc//foreign_cc:defs.bzl", "configure_make")

filegroup(
    name = "all",
    srcs = glob(["**"]),
)

configure_make(
    name = "iconv",
    configure_env_vars = select({
        "@platforms//os:macos": {"AR": ""},
        "//conditions:default": {},
    }),
    configure_in_place = True,
    configure_options = [
        "--enable-relocatable",
        "--enable-shared=no",
        "--enable-static=yes",
    ],
    lib_source = "@iconv//:all",
    make_commands = ["make install-lib"],
    out_static_libs = [
        "libiconv.a",
    ],
    visibility = ["//visibility:public"],
)
