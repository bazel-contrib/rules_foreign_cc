load("//tools/build_defs:configure.bzl", "configure_make")

configure_make(
    name = "libevent",
    lib_source = "@libevent//:all",
    configure_options = [
        "--enable-shared=no",
        "--disable-libevent-regress",
        "--disable-openssl",
    ],
    out_lib_dir = "lib",
)

cc_test(
    name = "libevent_echosrv1",
    srcs = ["libevent_echosrv1.c"],
    deps = [
        "libevent",
    ],
)
