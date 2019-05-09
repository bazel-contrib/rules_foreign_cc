load("@rules_foreign_cc//tools/build_defs:configure.bzl", "configure_make")

cc_library(
    name = "built_with_bazel",
    srcs = ["builtWithBazel.c"],
    hdrs = ["builtWithBazel.h"],
    includes = ["."],
)

configure_make(
    name = "simple",
    configure_in_place = True,
    lib_source = "//configure_with_bazel_transitive/simple_lib:simple_srcs",
    make_commands = [
        "make simple",
        "make install",
    ],
    deps = [":built_with_bazel"],
)

cc_test(
    name = "test",
    srcs = ["testSimple.c"],
    deps = [":simple"],
)
