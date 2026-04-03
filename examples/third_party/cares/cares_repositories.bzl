# buildifier: disable=module-docstring
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def cares_repositories():
    """Load all repositories needed for cares"""
    maybe(
        http_archive,
        name = "cares",
        build_file = Label("//cares:BUILD.cares.bazel"),
        sha256 = "4358939ff800b13b92f37d5fdda003718101faedfbdee792d6b79ddc1a53d890",
        strip_prefix = "c-ares-1.34.6",
        urls = [
            "https://mirror.bazel.build/github.com/c-ares/c-ares/archive/refs/tags/v1.34.6.tar.gz",
            "https://github.com/c-ares/c-ares/archive/refs/tags/v1.34.6.tar.gz",
        ],
    )
