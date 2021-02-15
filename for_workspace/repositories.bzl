""" Remote repositories, used by this project itself """

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def repositories():
    """Declare repositories used by `rules_foreign_cc`"""
    _all_content = """filegroup(name = "all_srcs", srcs = glob(["**"]), visibility = ["//visibility:public"])"""

    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "1c531376ac7e5a180e0237938a2536de0c54d93f5c278634818e0efc952dd56c",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
        ],
    )

    maybe(
        http_archive,
        name = "make",
        build_file_content = _all_content,
        sha256 = "e05fdde47c5f7ca45cb697e973894ff4f5d79e13b750ed57d7b66d8defc78e19",
        strip_prefix = "make-4.3",
        urls = [
            "http://mirror.rit.edu/gnu/make/make-4.3.tar.gz",
	    "http://ftp.snt.utwente.nl/pub/software/gnu/make/make-4.3.tar.gz",
        ],
    )

