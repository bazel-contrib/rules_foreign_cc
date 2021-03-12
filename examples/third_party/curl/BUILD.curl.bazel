load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")

filegroup(
    name = "all_srcs",
    srcs = glob(["**"]),
)

_CACHE_ENTRIES = {
    "BUILD_CURL_EXE": "off",
    "BUILD_SHARED_LIBS": "off",
    "CMAKE_PREFIX_PATH": ";$EXT_BUILD_DEPS/openssl",
    # TODO: ldap should likely be enabled
    "CURL_DISABLE_LDAP": "on",
}

_MACOS_CACHE_ENTRIES = dict(_CACHE_ENTRIES.items() + {
    "CMAKE_AR": "",
    "CMAKE_C_ARCHIVE_CREATE": "",
}.items())

_LINUX_CACHE_ENTRIES = dict(_CACHE_ENTRIES.items() + {
    "CMAKE_C_FLAGS": "-fPIC",
}.items())

cmake(
    name = "curl",
    cache_entries = select({
        "@platforms//os:linux": _LINUX_CACHE_ENTRIES,
        "@platforms//os:macos": _MACOS_CACHE_ENTRIES,
        "//conditions:default": _CACHE_ENTRIES,
    }),
    cmake_options = select({
        "@platforms//os:windows": ["-GNinja"],
        "//conditions:default": [],
    }),
    generate_crosstool_file = False,
    lib_source = ":all_srcs",
    make_commands = select({
        "@platforms//os:windows": [
            "ninja",
            "ninja install",
        ],
        "//conditions:default": [
            "make",
            "make install",
        ],
    }),
    out_static_libs = select({
        "@platforms//os:windows": ["libcurl.lib"],
        "//conditions:default": ["libcurl.a"],
    }),
    visibility = ["//visibility:public"],
    deps = [
        "@zlib//:zlib",
    ] + select({
        "@platforms//os:windows": [],
        "//conditions:default": [
            "@openssl//:openssl",
        ],
    }),
)
