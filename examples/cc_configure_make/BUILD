load("//cc_configure_make:def.bzl", "cc_configure_make")

cc_configure_make(
    name = "libevent",
    src = "@libevent//:all",
    configure_flags = [
        "--enable-shared=no",
        "--disable-libevent-regress",
        "--disable-openssl",
    ],
    out_lib_path = "lib/libevent.a",
)

cc_binary(
    name = "libevent_echosrv1",
    srcs = ["libevent_echosrv1.c"],
    deps = [
        "libevent",
    ],
)
