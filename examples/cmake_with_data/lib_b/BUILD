load("@rules_cc//cc:defs.bzl", "cc_library")

cc_library(
    name = "lib_b",
    srcs = ["src/lib_b.cpp"],
    hdrs = ["src/lib_b.h"],
    linkstatic = False,
    visibility = ["//cmake_with_data:__pkg__"],
)
