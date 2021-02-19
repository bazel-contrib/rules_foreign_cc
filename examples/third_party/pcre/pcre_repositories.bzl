"""A module defining the third party dependency PCRE"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def pcre_repositories():
    maybe(
        http_archive,
        name = "pcre",
        build_file = Label("//pcre:BUILD.pcre.bazel"),
        strip_prefix = "pcre-8.43",
        urls = [
            "https://mirror.bazel.build/ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz",
            "https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz",
        ],
        sha256 = "0b8e7465dc5e98c757cc3650a20a7843ee4c3edf50aaf60bb33fd879690d2c73",
    )
