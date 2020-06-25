package(default_visibility = ["//visibility:public"])

load("@rules_foreign_cc//tools/build_defs:configure.bzl", "configure_make")
load("@rules_foreign_cc//tools/build_defs:framework.bzl", "foreign_runtime")

# This example tests a somewhat complex dependency scheme::
#
#     ncurses <- readline <- postgres
#                 openssl <--/

CONFIGURE_ENV_VARS = select({
    # See https://github.com/bazelbuild/rules_foreign_cc/issues/338
    "@bazel_tools//src/conditions:darwin": {"AR": ""},
    "//conditions:default": {},
})

sh_library(
    name = "exec",
    srcs = ["exec.sh"],
)

configure_make(
    name = "ncurses",
    configure_env_vars = CONFIGURE_ENV_VARS,
    configure_options = [
        "--without-manpages",
        "--without-debug",
        "--without-ada",
        "--without-tests",
        "--without-tack",
        "--disable-home-terminfo",
        "--disable-db-install",
        "--enable-interop",
    ] + select({
        "@bazel_tools//src/conditions:darwin": [],
        "//conditions:default": [
            # The configure script checks this value and when run under Bazel on
            # bare-bones Debian 10 it gets a value of "unknown" which triggers
            # downstream errors.  When run in Debian 10 in a user shell, this is
            # the result (and it's also a hard coded value in the configure
            # script).
            "ARFLAGS=-curvU",
        ],
    }),
    lib_source = "@ncurses//:all",
    static_libraries = ["libncurses.a"],
)

configure_make(
    name = "readline",
    configure_env_vars = CONFIGURE_ENV_VARS,
    lib_source = "@readline//:all",
    static_libraries = [
        "libreadline.a",
        "libhistory.a",
    ],
    deps = [":ncurses"],
)

configure_make(
    name = "openssl",
    configure_command = "config",
    configure_env_vars = CONFIGURE_ENV_VARS,
    lib_source = "@openssl//:all",
    static_libraries = [
        "libssl.a",
        "libcrypto.a",
    ],
)

configure_make(
    name = "postgres",
    binaries = [
        "psql",
        "pg_ctl",
        "postgres",
        "initdb",
    ],
    configure_env_vars = CONFIGURE_ENV_VARS,
    configure_options = ["--with-openssl"],
    lib_source = "@postgres//:all",
    static_libraries = ["libpq.a"],
    deps = [
        ":openssl",
        ":readline",
    ],
)

foreign_runtime(
    name = "postgres.runtime",
    srcs = [":postgres"],
)

runtime_data = select({
    "@bazel_tools//src/conditions:darwin": [],
    "//conditions:default": [":postgres.runtime"],
})

filegroup(
    name = "psql_binary",
    srcs = [":postgres"],
    output_group = "psql",
)

sh_binary(
    name = "psql",
    srcs = [":exec"],
    args = ["$(location :psql_binary)"],
    data = [":psql_binary"] + runtime_data,
    deps = ["@bazel_tools//tools/bash/runfiles"],
)

sh_binary(
    name = "check_ldd",
    srcs = [":exec"],
    args = [
        "ldd",
        "$(location :psql_binary)",
    ],
    data = [":psql_binary"] + runtime_data,
    deps = ["@bazel_tools//tools/bash/runfiles"],
)
