load("@rules_foreign_cc//tools/build_defs:configure.bzl", "configure_make")

configure_make(
    name = "libevent",
    # libevent script uses it's own libtool for linking;
    # so do not specify linker tool for it
    # (otherwise, if the libtool from bazel's toolchain is supplied,
    # the build script has problems with passing output file to libtool)
    # see #315
    configure_env_vars = {
        "AR": "",
    },
    configure_options = [
        "--enable-shared=no",
        "--disable-libevent-regress",
        "--disable-openssl",
    ],
    lib_source = "@libevent//:all",
    out_lib_dir = "lib",
)

cc_test(
    name = "libevent_echosrv1",
    srcs = ["libevent_echosrv1.c"],
    deps = [
        "libevent",
    ],
)
