load("//cc_configure_make:cc_configure_make.bzl", "cc_configure_make_tmp_macros")

cc_configure_make_tmp_macros(
    name = "libevent",
    srcs = "@libevent//:all",
    configure_flags = [
        "--enable-shared=no",
        "--disable-libevent-regress",
        "--disable-openssl",
    ],
)

cc_binary(
    name = "libevent_echosrv1",
    srcs = ["libevent_echosrv1.c"],
    deps = [
        "libevent",
    ],
)
