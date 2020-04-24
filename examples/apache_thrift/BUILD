load("@rules_foreign_cc//tools/build_defs:configure.bzl", "configure_make")
load("@rules_foreign_cc//tools/build_defs:boost_build.bzl", "boost_build")
load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

config_setting(
    name = "macos",
    values = {
        "apple_platform_type": "macos",
        "cpu": "darwin",
    },
)

configure_env_vars = select({
    ":macos": {
        "AR": "/usr/bin/ar",
    },
    "//conditions:default": {},
})

configure_make(
    name = "openssl",
    configure_command = "config",
    configure_env_vars = configure_env_vars,
    configure_options = [
        "no-shared",
    ],
    lib_source = "@openssl//:all",
    static_libraries = [
        "libcrypto.a",
        "libssl.a",
    ],
)

configure_make(
    name = "bison",
    binaries = [
        "bison",
        "yacc",
    ],
    configure_env_vars = configure_env_vars,
    lib_source = "@bison//:all",
    static_libraries = [
        "liby.a",
    ],
)

configure_make(
    name = "libevent",
    configure_env_vars = configure_env_vars,
    configure_options = [
        "--disable-shared",
        "--disable-libevent-regress",
        "--disable-openssl",
    ],
    lib_source = "@libevent//:all",
    static_libraries = [
        "libevent.a",
        "libevent_core.a",
        "libevent_extra.a",
        "libevent_pthreads.a",
    ],
)

# Not the most efficient but it gets it done for Thrift
boost_build(
    name = "boost",
    headers_only = True,
    lib_source = "@boost//:all",
)

# We need this filegroup so rules_foreign_cc can correctly place the binary in the sandbox's PATH,
# effectively making it discoverable by apache thrift's configure script.
filegroup(
    name = "bison-bin",
    srcs = [":bison"],
    output_group = "bison",
)

cmake_external(
    name = "thrift-bin",
    binaries = [
        "thrift",
    ],
    cache_entries = {
        "BUILD_TESTING": "OFF",
        "BUILD_TUTORIALS": "OFF",
        "BUILD_C_GLIB": "OFF",
        "BUILD_JAVA": "OFF",
        "THRIFT_COMPILER_C_GLIB": "OFF",
        "THRIFT_COMPILER_D": "OFF",
        "OPENSSL_ROOT_DIR": "$EXT_BUILD_DEPS/openssl",
        "LIBEVENT_ROOT": "$EXT_BUILD_DEPS/libevent",
    },
    lib_source = "@thrift//:all",
    tools_deps = [
        ":bison-bin",
    ],
    deps = [
        ":boost",
        ":libevent",
        ":openssl",
    ],
)

# doesn't work, rules_foreign_cc loses Apache Thrift local libtool script and that
# causes make to fail linking object files.
# configure_make(
#     name = "thrift",
#     configure_in_place = True,
#     binaries = [
#         "thrift",
#     ],
#     configure_env_vars = configure_env_vars,
#     configure_options = [
#         "--disable-shared",
#         "--disable-debug",
#         "--disable-tests",
#         "--disable-tutorial",
#     ],
#     lib_source = "@thrift//:all",
#     visibility = [
#         "//visibility:public",
#     ],
#     tools_deps = [
#         ":bison-bin",
#     ],
#     deps = [
#         ":libevent",
#         ":openssl",
#         ":boost",
#     ],
#     static_libraries = [
#         "libparse.a",
#         "libthrift.a",
#     ]
# )
