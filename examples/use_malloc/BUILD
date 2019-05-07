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
)

# This currently gives an error:
# "ERROR: <...>/use_malloc/BUILD:17:14: in malloc attribute of cc_test rule //:test:
# configure_make rule '//:gperftools_build' is misplaced here (expected cc_library)"
cc_test(
    name = "test",
    srcs = ["hello.cpp"],
    malloc = ":gperftools_build",
)
