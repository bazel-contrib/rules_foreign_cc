load("@rules_foreign_cc//tools/build_defs:configure.bzl", "configure_make")

configure_make(
    name = "apr",
    lib_source = "@apr//:all",
    static_libraries = ["libapr-1.a"],
    shared_libraries = ["libapr-1.so"],
)

configure_make(
    name = "apr_util",
    lib_source = "@apr_util//:all",
    deps = [":apr"],
    configure_options = [
        "--with-apr=$$EXT_BUILD_DEPS$$/apr",
        ],
    static_libraries = ["libaprutil-1.a"],
    shared_libraries = ["libaprutil-1.so"],
)

configure_make(
    name = "pcre",
    lib_source = "@pcre//:all",
    static_libraries = ["libpcre.a"],
    shared_libraries = ["libpcre.so.1"],
)

configure_make(
    name = "apache_httpd",
    configure_options = [
        "--with-apr=$$EXT_BUILD_DEPS$$/apr",
        "--with-apr-util=$$EXT_BUILD_DEPS$$/apr_util",
        "--with-pcre=$$EXT_BUILD_DEPS$$/pcre",
        "CFLAGS='-Dredacted=\"redacted\"'",
    ],
    lib_source = "@apache_httpd//:all",
    binaries = [
        "httpd",
    ],
    deps = [
        ":apr",
        ":apr_util",
        ":pcre",
    ],
    visibility = [
        "//visibility:public"
        ],
)

filegroup(
    name = "httpd_dir",
    srcs = [
        ":apache_httpd",
    ],
    output_group = "gen_dir"
)

filegroup(
    name = "pcre_dir",
    srcs = [
        ":pcre",
    ],
    output_group = "gen_dir"
)

filegroup(
    name = "apr_dir",
    srcs = [
        ":apr",
    ],
    output_group = "gen_dir"
)

filegroup(
    name = "apr_util_dir",
    srcs = [
        ":apr_util",
    ],
    output_group = "gen_dir"
)

sh_test(
    name = "test",
    srcs = [
        "t.sh",
    ],
    args = ["$(location httpd_dir)/bin/httpd $(location pcre_dir)/lib $(location apr_dir)/lib $(location apr_util_dir)/lib"],
    data = [
        ":httpd_dir",
        ":apr_dir",
        ":apr_util_dir",
        ":pcre_dir",
    ],
)
