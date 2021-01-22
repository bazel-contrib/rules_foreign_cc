load(":native_tools_toolchain.bzl", "native_tool_toolchain")
load("//for_workspace:make_build.bzl", "make_tool")
load("//for_workspace:cmake_build.bzl", "cmake_tool")
load("//for_workspace:ninja_build.bzl", "ninja_tool")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

native_tool_toolchain(
    name = "preinstalled_make",
    path = "make",
    visibility = ["//visibility:public"],
)

make_tool(
    name = "make_tool",
    make_srcs = "@make//:all",
)

native_tool_toolchain(
    name = "built_make",
    path = "make/bin/make",
    target = ":make_tool",
    visibility = ["//visibility:public"],
)

native_tool_toolchain(
    name = "preinstalled_cmake",
    path = "cmake",
    visibility = ["//visibility:public"],
)

cmake_tool(
    name = "cmake_tool",
    cmake_srcs = "@cmake//:all",
)

native_tool_toolchain(
    name = "built_cmake",
    path = "cmake/bin/cmake",
    target = ":cmake_tool",
    visibility = ["//visibility:public"],
)

native_tool_toolchain(
    name = "preinstalled_ninja",
    path = "ninja",
    visibility = ["//visibility:public"],
)

ninja_tool(
    name = "ninja_tool",
    ninja_srcs = "@ninja_build//:all",
)

native_tool_toolchain(
    name = "built_ninja",
    path = "ninja/ninja",
    target = ":ninja_tool",
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "bzl_srcs",
    srcs = glob(["**/*.bzl"]),
    visibility = ["//:__subpackages__"],
)
