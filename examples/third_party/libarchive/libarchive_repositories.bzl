"""A module defining the third party dependency libarchive."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def libarchive_repositories():
    maybe(
        http_archive,
        name = "examples_libarchive",
        build_file = Label("//libarchive:BUILD.libarchive.bazel"),
        sha256 = "879acd83c3399c7caaee73fe5f7418e06087ab2aaf40af3e99b9e29beb29faee",
        strip_prefix = "libarchive-3.7.7",
        urls = [
            "https://github.com/libarchive/libarchive/releases/download/v3.7.7/libarchive-3.7.7.tar.xz",
        ],
    )
