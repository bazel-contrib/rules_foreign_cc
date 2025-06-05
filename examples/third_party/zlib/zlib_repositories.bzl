"""A module defining the third party dependency zlib"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def zlib_repositories():
    maybe(
        http_archive,
        name = "zlib",
        build_file = Label("//zlib:BUILD.zlib.bazel"),
        sha256 = "9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23",
        strip_prefix = "zlib-1.3.1",
        urls = [
            "https://zlib.net/zlib-1.3.1.tar.gz",
            "https://zlib.net/archive/zlib-1.3.1.tar.gz",
        ],
    )
