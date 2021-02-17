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
        name = "boost",
        build_file_content = _ALL_CONTENT,
        strip_prefix = "boost_1_68_0",
        sha256 = "da3411ea45622579d419bfda66f45cd0f8c32a181d84adfa936f5688388995cf",
        urls = [
            "https://mirror.bazel.build/dl.bintray.com/boostorg/release/1.68.0/source/boost_1_68_0.tar.gz",
            "https://dl.bintray.com/boostorg/release/1.68.0/source/boost_1_68_0.tar.gz",
        ],
    )
