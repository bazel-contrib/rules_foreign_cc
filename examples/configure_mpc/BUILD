load("@rules_foreign_cc//tools/build_defs:configure.bzl", "configure_make")

configure_make(
    name = "gmp",
    lib_source = "@gmp//:all",
    shared_libraries = ["libgmp.so"],
    static_libraries = ["libgmp.a"],
    visibility = ["//visibility:public"],
)

configure_make(
    name = "mpfr",
    lib_source = "@mpfr//:all",
    shared_libraries = ["libmpfr.so"],
    static_libraries = ["libmpfr.a"],
    visibility = ["//visibility:public"],
    deps = [":gmp"],
)

configure_make(
    name = "mpc",
    autoreconf = True,
    autoreconf_options = [
        "-i",
        "-f",
        "-v",
    ],
    configure_in_place = True,
    lib_source = "@mpc//:all",
    shared_libraries = ["libmpc.so"],
    static_libraries = ["libmpc.a"],
    visibility = ["//visibility:public"],
    deps = [
        ":gmp",
        ":mpfr",
    ],
)

cc_test(
    name = "test_mpc",
    srcs = ["mpc_test.c"],
    deps = [":mpc"],
)

test_suite(
    name = "configure_mpc_tests",
    tests = [":test_mpc"],
)
