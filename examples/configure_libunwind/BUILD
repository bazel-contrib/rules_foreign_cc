load("@rules_foreign_cc//tools/build_defs:configure.bzl", "configure_make")

configure_make(
    name = "libunwind",
    autogen = True,
    configure_in_place = True,
    configure_options = [
        "--disable-coredump",
        "--disable-ptrace",
        "--disable-setjmp",
        "--disable-documentation",
        "--disable-weak-backtrace",
    ],
    lib_source = "@libunwind//:all",
    shared_libraries = ["libunwind.so"],
    static_libraries = ["libunwind.a"],
    visibility = ["//visibility:public"],
)

cc_test(
    name = "test_libunwind",
    srcs = ["libunwind_test.c"],
    deps = [":libunwind"],
)

test_suite(
    name = "configure_libunwind_tests",
    tests = [":test_libunwind"],
)
