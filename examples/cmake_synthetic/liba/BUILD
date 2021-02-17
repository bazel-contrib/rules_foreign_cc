load("@rules_cc//cc:defs.bzl", "cc_library")

filegroup(
    name = "a_srcs",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "lib_a_bazel",
    srcs = ["src/liba.cpp"],
    hdrs = ["src/liba.h"],
    includes = ["src"],
    visibility = ["//visibility:public"],
)

cc_binary(
    name = "liba.so",
    linkshared = 1,
    linkstatic = 1,
    srcs = ["src/liba.cpp", "src/liba.h"],
    linkopts = select({
        "//:macos": ["-Wl,-install_name", "-Wl,@rpath/liba.so"]
    })
)

cc_import(
    name = "lib_a_so_import",
    shared_library = "liba.so",
)

cc_library(
    name = "lib_a_so",
    deps = [":lib_a_so_import"],
    hdrs = ["src/liba.h"],
    includes = ["src"],
    visibility = ["//visibility:public"],
)
