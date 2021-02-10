load("@rules_cc//cc:defs.bzl", "cc_test")
load("@rules_foreign_cc//tools/build_defs:make.bzl", "make")

make(
    name = "make_lib",
    tools_deps = ["//simple_make/code:clang_wrapper.sh"],
    env = {
        "CLANG_WRAPPER": "$(execpath //simple_make/code:clang_wrapper.sh)",
    },
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
