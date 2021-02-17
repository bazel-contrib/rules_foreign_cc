# buildifier: disable=module-docstring
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

_ALL_CONTENT = """\
filegroup(
    name = "all", 
    srcs = glob(["**"]), 
    visibility = ["//visibility:public"],
)
"""

def repositories():
    """Load all repositories needed for the targets of rules_foreign_cc_examples_third_party"""
    maybe(
        http_archive,
        name = "libevent",
        build_file_content = _ALL_CONTENT,
        strip_prefix = "libevent-2.1.8-stable",
        urls = [
            "https://mirror.bazel.build/github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz",
            "https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz",
        ],
        sha256 = "965cc5a8bb46ce4199a47e9b2c9e1cae3b137e8356ffdad6d94d3b9069b71dc2",
    )
