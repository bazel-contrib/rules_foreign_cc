# buildifier: disable=module-docstring
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def cares_repositories():
    """Load all repositories needed for cares"""
    maybe(
        http_archive,
        name = "cares",
        build_file = Label("//cares:BUILD.cares.bazel"),
        sha256 = "912dd7cc3b3e8a79c52fd7fb9c0f4ecf0aaa73e45efda880266a2d6e26b84ef5",
        strip_prefix = "c-ares-1.34.6",
        urls = [
            "https://mirror.bazel.build/github.com/c-ares/c-ares/releases/download/v1.34.6/c-ares-1.34.6.tar.gz",
            "https://github.com/c-ares/c-ares/releases/download/v1.34.6/c-ares-1.34.6.tar.gz",
        ],
    )
