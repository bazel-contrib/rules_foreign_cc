load(":defs.bzl", "build_part")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

toolchain_type(
    name = "shell_commands",
    visibility = ["//visibility:public"],
)

build_part(":shell_commands")

bzl_library(
    name = "bzl_srcs",
    srcs = glob(["**/*.bzl"]) + [
        "@commands_overloads//:toolchain_data_defs.bzl",
    ],
    visibility = ["//:__subpackages__"],
    deps = ["//tools/build_defs/shell_toolchain/toolchains/impl:bzl_srcs"],
)
