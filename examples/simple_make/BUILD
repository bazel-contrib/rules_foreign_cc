load("@rules_foreign_cc//tools/build_defs:make.bzl", "make")

make(
    name = "make_lib",
    lib_source = "//simple_make/code:sources",
    static_libraries = ["liba.a"],
)

cc_test(
    name = "test_lib",
    srcs = [
        "test_libb.cpp",
    ],
    tags = ["windows"],
    deps = [
        ":make_lib",
    ],
)
