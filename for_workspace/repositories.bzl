""" Remote repositories, used by this project itself """

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def repositories():
    _all_content = """filegroup(name = "all", srcs = glob(["**"]), visibility = ["//visibility:public"])"""

    http_archive(
        name = "bazel_skylib",
        sha256 = "1c531376ac7e5a180e0237938a2536de0c54d93f5c278634818e0efc952dd56c",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
        ],
    )

    http_archive(
        name = "make",
        build_file_content = _all_content,
        sha256 = "e05fdde47c5f7ca45cb697e973894ff4f5d79e13b750ed57d7b66d8defc78e19",
        strip_prefix = "make-4.3",
        urls = [
            "http://mirror.rit.edu/gnu/make/make-4.3.tar.gz",
        ],
    )

    http_archive(
        name = "ninja_build",
        build_file_content = _all_content,
        sha256 = "a6b6f7ac360d4aabd54e299cc1d8fa7b234cd81b9401693da21221c62569a23e",
        strip_prefix = "ninja-1.10.1",
        urls = [
            "https://github.com/ninja-build/ninja/archive/v1.10.1.tar.gz",
        ],
    )

    http_archive(
        name = "cmake",
        build_file_content = _all_content,
        sha256 = "5d4e40fc775d3d828c72e5c45906b4d9b59003c9433ff1b36a1cb552bbd51d7e",
        strip_prefix = "cmake-3.18.2",
        urls = [
            "https://github.com/Kitware/CMake/releases/download/v3.18.2/cmake-3.18.2.tar.gz",
        ],
    )
