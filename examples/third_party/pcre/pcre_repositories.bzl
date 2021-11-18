"""A module defining the third party dependency PCRE"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def pcre_repositories():
    maybe(
        http_archive,
        name = "pcre",
        build_file = Label("//pcre:BUILD.pcre.bazel"),
        strip_prefix = "pcre-8.45",
        sha256 = "4e6ce03e0336e8b4a3d6c2b70b1c5e18590a5673a98186da90d4f33c23defc09",
        urls = [
            "https://mirror.bazel.build/downloads.sourceforge.net/project/pcre/pcre/8.45/pcre-8.45.tar.gz",
            "https://downloads.sourceforge.net/project/pcre/pcre/8.45/pcre-8.45.tar.gz",
        ],
    )
