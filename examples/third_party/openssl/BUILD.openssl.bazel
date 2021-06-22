"""An openssl build file based on a snippet found in the github issue:
https://github.com/bazelbuild/rules_foreign_cc/issues/337
"""

load("@rules_foreign_cc//foreign_cc:defs.bzl", "configure_make")

# Read https://wiki.openssl.org/index.php/Compilation_and_Installation

filegroup(
    name = "all_srcs",
    srcs = glob(["**"]),
)

CONFIGURE_OPTIONS = [
    "no-comp",
    "no-idea",
    "no-weak-ssl-ciphers",
]

configure_make(
    name = "openssl",
    configure_command = "config",
    configure_in_place = True,
    configure_options = select({
        "@platforms//os:macos": [
            "ARFLAGS=r",
            "no-afalgeng",
            "no-asm",
            "no-shared",
        ] + CONFIGURE_OPTIONS,
        "//conditions:default": [
            "no-shared",
        ] + CONFIGURE_OPTIONS,
    }),
    env = select({
        "@platforms//os:macos": {"AR": ""},
        "//conditions:default": {},
    }),
    lib_source = ":all_srcs",
    out_static_libs = [
        "libcrypto.a",
        "libssl.a",
    ],
    targets = [
        "build_libs",
        "install_dev",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "gen_dir",
    srcs = [":openssl"],
    output_group = "gen_dir",
    visibility = ["//visibility:public"],
)
