"""A module defining the third party dependency boost"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def boost_repositories():
    maybe(
        http_archive,
        name = "boost",
        build_file = Label("//boost:BUILD.boost.bazel"),
        sha256 = "de5e6b0e4913395c6bdfa90537febd9028ea4c0735d2cdb0cd9b45d5f51264f5",
        strip_prefix = "boost_1_91_0",
        urls = [
            "https://archives.boost.io/release/1.91.0/source/boost_1_91_0.tar.bz2",
        ],
    )
