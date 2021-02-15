load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

_DEPRECATION_NOTICE = "This target has moved to `@rules_foreign_cc//toolchains/...`"

alias(
    name = "preinstalled_make",
    actual = "//toolchains:preinstalled_make",
    deprecation = _DEPRECATION_NOTICE,
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

alias(
    name = "make_tool",
    actual = "//toolchains:make_tool",
    deprecation = _DEPRECATION_NOTICE,
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

alias(
    name = "built_make",
    actual = "//toolchains:built_make",
    deprecation = _DEPRECATION_NOTICE,
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

alias(
    name = "preinstalled_cmake",
    actual = "//toolchains:preinstalled_cmake",
    deprecation = _DEPRECATION_NOTICE,
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

alias(
    name = "built_cmake",
    actual = "//toolchains:built_cmake",
    deprecation = _DEPRECATION_NOTICE,
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

alias(
    name = "preinstalled_ninja",
    actual = "//toolchains:preinstalled_ninja",
    deprecation = _DEPRECATION_NOTICE,
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

alias(
    name = "built_ninja",
    actual = "//toolchains:built_ninja",
    deprecation = _DEPRECATION_NOTICE,
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "bzl_srcs",
    srcs = glob(["**/*.bzl"]),
    visibility = ["//visibility:public"],
)
