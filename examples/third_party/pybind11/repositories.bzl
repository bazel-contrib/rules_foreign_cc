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
        name = "pybind11",
        build_file_content = _ALL_CONTENT,
        strip_prefix = "pybind11-2.2.3",
        urls = [
            "https://mirror.bazel.build/github.com/pybind/pybind11/archive/v2.2.3.tar.gz",
            "https://github.com/pybind/pybind11/archive/v2.2.3.tar.gz",
        ],
        sha256 = "3a3b7b651afab1c5ba557f4c37d785a522b8030dfc765da26adc2ecd1de940ea",
    )
