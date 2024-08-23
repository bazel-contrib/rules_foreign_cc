"""A module defining the third party dependency gperftools"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def gperftools_repositories():
    maybe(
        http_archive,
        name = "gperftools",
        build_file = Label("//gperftools:BUILD.gperftools.bazel"),
        sha256 = "",
        strip_prefix = "gperftools-2.15",
        urls = ["https://github.com/gperftools/gperftools/releases/download/gperftools-2.15/gperftools-2.15.tar.gz"],
    )
