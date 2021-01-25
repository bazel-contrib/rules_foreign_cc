load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files(
    [
        "make_build.bzl",
        "cmake_build.bzl",
        "ninja_build.bzl",
        "install_ws_dependency.bzl",
    ],
)

bzl_library(
    name = "bzl_srcs",
    srcs = glob(["**/*.bzl"]),
    visibility = ["//:__subpackages__"],
)
