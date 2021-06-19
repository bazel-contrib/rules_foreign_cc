"""A module defining the third party dependency file"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def file_repositories():
    maybe(
        http_archive,
        name = "file",
        build_file = Label("//file:BUILD.file.bazel"),
        strip_prefix = "file-5.40",
        sha256 = "167321f43c148a553f68a0ea7f579821ef3b11c27b8cbe158e4df897e4a5dd57",
        urls = ["https://astron.com/pub/file/file-5.40.tar.gz"],
    )
