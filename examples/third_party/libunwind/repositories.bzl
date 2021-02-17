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
        name = "libunwind",
        build_file_content = _ALL_CONTENT,
        strip_prefix = "libunwind-9165d2a150d707d3037c2045f2cdc0fabd5fee98",
        urls = [
            "https://mirror.bazel.build/github.com/libunwind/libunwind/archive/9165d2a150d707d3037c2045f2cdc0fabd5fee98.zip",
            "https://github.com/libunwind/libunwind/archive/9165d2a150d707d3037c2045f2cdc0fabd5fee98.zip",
        ],
        sha256 = "f83c604cde80a49af91345a1ff3f4558958202989fb768e6508963e24ea2524c",
    )
