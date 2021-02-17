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
        name = "nghttp2",
        build_file_content = _ALL_CONTENT,
        patch_args = ["-p1"],
        patch_cmds = ["find . -name '*.sh' -exec sed -i.orig '1s|#!/usr/bin/env sh\\$|/bin/sh\\$|' {} +"],
        patches = ["@rules_foreign_cc_examples_third_party//nghttp2:nghttp2.patch"],
        strip_prefix = "nghttp2-e5b3f9addd49bca27e2f99c5c65a564eb5c0cf6d",
        urls = [
            "https://mirror.bazel.build/github.com/nghttp2/nghttp2/archive/e5b3f9addd49bca27e2f99c5c65a564eb5c0cf6d.tar.gz",
            "https://github.com/nghttp2/nghttp2/archive/e5b3f9addd49bca27e2f99c5c65a564eb5c0cf6d.tar.gz",
        ],
        sha256 = "d3012f33384f6ff980ebbe75efcb6fc5402dca5f82f092d21200b3b12425d3f5",
    )
