load("@rules_foreign_cc//tools/build_defs:configure.bzl", "configure_make")

configure_make(
    name = "gperftools_build",
    configure_options = [
        "--enable-shared=no",
        "--enable-frame-pointers",
        "--disable-libunwind",
    ],
    lib_source = "@gperftools//:all",
    static_libraries = ["libtcmalloc_and_profiler.a"],
    configure_env_vars = {
      "AR": "",
    }
)

cc_test(
    name = "test",
    srcs = ["hello.cpp"],
    deps = [":gperftools_build"],
)
