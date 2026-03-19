"""A module defining the third party dependency gperftools"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def gperftools_repositories():
    maybe(
        http_archive,
        name = "gperftools",
        build_file = Label("//gperftools:BUILD.gperftools.bazel"),
        sha256 = "f12624af5c5987f2cc830ee534f754c3c5961eec08004c26a8b80de015cf056f",
        strip_prefix = "gperftools-2.16",
        urls = ["https://github.com/gperftools/gperftools/releases/download/gperftools-2.16/gperftools-2.16.tar.gz"],
    )
