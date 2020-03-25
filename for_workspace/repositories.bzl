""" Remote repositories, used by this project itself """

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def repositories():
    _all_content = """filegroup(name = "all", srcs = glob(["**"]), visibility = ["//visibility:public"])"""

    http_archive(
        name = "bazel_skylib",
        sha256 = "97e70364e9249702246c0e9444bccdc4b847bed1eb03c5a3ece4f83dfe6abc44",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
        ],
    )

    http_archive(
        name = "ninja_build",
        build_file_content = _all_content,
        sha256 = "86b8700c3d0880c2b44c2ff67ce42774aaf8c28cbf57725cb881569288c1c6f4",
        strip_prefix = "ninja-1.8.2",
        urls = [
            "https://github.com/ninja-build/ninja/archive/v1.8.2.tar.gz",
        ],
    )

    http_archive(
        name = "cmake",
        build_file_content = _all_content,
        sha256 = "019aa2afdf650d27bd70407e0a8183ce2f3fce0429e82d1ced234aed942c9a0b",
        strip_prefix = "CMake-3.12.1",
        urls = [
            "https://github.com/Kitware/CMake/archive/v3.12.1.tar.gz",
        ],
    )
