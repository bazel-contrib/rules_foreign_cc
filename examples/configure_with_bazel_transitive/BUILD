load("@rules_foreign_cc//tools/build_defs:configure.bzl", "configure_make")

configure_make(
    name = "simple",
    configure_in_place = True,
    lib_source = "//configure_with_bazel_transitive/simple_lib:simple_srcs",
    make_commands = [
        "make simple",
        "make install",
    ],
    deps = [
        "//configure_with_bazel_transitive/built_with_bazel:built_with_bazel",
        "//configure_with_bazel_transitive/built_with_bazel_2:built_with_bazel_2",
    ],
)

cc_test(
    name = "test",
    srcs = ["testSimple.c"],
    deps = [":simple"],
)
