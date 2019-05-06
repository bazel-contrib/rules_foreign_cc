""" Remote repositories, used by this project itself """

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def repositories():
    _all_content = """filegroup(name = "all", srcs = glob(["**"]), visibility = ["//visibility:public"])"""

    http_archive(
        name = "bazel_skylib",
        type = "tar.gz",
        url = "https://github.com/bazelbuild/bazel-skylib/releases/download/0.8.0/bazel-skylib.0.8.0.tar.gz",
        sha256 = "2ef429f5d7ce7111263289644d233707dba35e39696377ebab8b0bc701f7818e",
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
        strip_prefix = "CMake-3.12.1",
        urls = [
            "https://github.com/Kitware/CMake/archive/v3.12.1.tar.gz",
        ],
    )
