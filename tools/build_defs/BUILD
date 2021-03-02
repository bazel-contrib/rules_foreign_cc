load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

toolchain_type(
    name = "cmake_toolchain",
    visibility = ["//visibility:public"],
)

toolchain_type(
    name = "ninja_toolchain",
    visibility = ["//visibility:public"],
)

toolchain_type(
    name = "make_toolchain",
    visibility = ["//visibility:public"],
)

toolchain(
    name = "built_cmake_toolchain",
    toolchain = "@rules_foreign_cc//toolchains:built_cmake",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:cmake_toolchain",
)

toolchain(
    name = "built_ninja_toolchain",
    toolchain = "@rules_foreign_cc//toolchains:built_ninja",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:ninja_toolchain",
)

toolchain(
    name = "built_make_toolchain",
    toolchain = "@rules_foreign_cc//toolchains:built_make",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:make_toolchain",
)


# Preinstalled cmake will always be the default, if toolchain with more exact constraints
# is not defined before; registered from workspace_definitions.bzl#rules_foreign_cc_dependencies
toolchain(
    name = "preinstalled_cmake_toolchain",
    toolchain = "@rules_foreign_cc//toolchains:preinstalled_cmake",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:cmake_toolchain",
)

# Preinstalled ninja will always be the default, if toolchain with more exact constraints
# is not defined before; registered from workspace_definitions.bzl#rules_foreign_cc_dependencies
toolchain(
    name = "preinstalled_ninja_toolchain",
    toolchain = "@rules_foreign_cc//toolchains:preinstalled_ninja",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:ninja_toolchain",
)

# Preinstalled make will always be the default, if toolchain with more exact constraints
# is not defined before; registered from workspace_definitions.bzl#rules_foreign_cc_dependencies
toolchain(
    name = "preinstalled_make_toolchain",
    toolchain = "@rules_foreign_cc//toolchains:preinstalled_make",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:make_toolchain",
)

bzl_library(
    name = "bzl_srcs",
    srcs = glob(["**/*.bzl"]),
    visibility = ["//:__subpackages__"],
    deps = [
        "//tools/build_defs/native_tools:bzl_srcs",
        "//tools/build_defs/shell_toolchain/polymorphism:bzl_srcs",
        "//tools/build_defs/shell_toolchain/toolchains:bzl_srcs",
        "@bazel_skylib//lib:collections",
        "@bazel_skylib//lib:versions",
    ],
)
