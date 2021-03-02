"""
Defines repositories and register toolchains for versions of the tools built
from source
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

_ALL_CONTENT = """\
filegroup(
    name = "all_srcs",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)
"""

# buildifier: disable=unnamed-macro
def built_toolchains(cmake_version, make_version, ninja_version):
    """Register toolchains for built tools that will be built from source"""
    _cmake_toolchain(cmake_version)
    _make_toolchain(make_version)
    _ninja_toolchain(ninja_version)


def _cmake_toolchain(version):
    native.register_toolchains(
        "@rules_foreign_cc//tools/build_defs:built_cmake_toolchain",
    )
    if version == "3.19.6":
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "ec87ab67c45f47c4285f204280c5cde48e1c920cfcfed1555b27fb3b1a1d20ba",
            strip_prefix = "cmake-3.19.6",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.19.6/cmake-3.19.6.tar.gz",
            ],
        )
        return

    fail("Unsupported cmake version: " + str(version))


def _make_toolchain(version):
    native.register_toolchains(
        "@rules_foreign_cc//tools/build_defs:built_make_toolchain",
    )
    if version == "4.3":
        maybe(
            http_archive,
            name = "gnumake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "e05fdde47c5f7ca45cb697e973894ff4f5d79e13b750ed57d7b66d8defc78e19",
            strip_prefix = "make-4.3",
            urls = [
                "http://ftpmirror.gnu.org/gnu/make/make-4.3.tar.gz",
            ],
        )
        return

    fail("Unsupported make version: " + str(version))


def _ninja_toolchain(version):
    native.register_toolchains(
        "@rules_foreign_cc//tools/build_defs:built_ninja_toolchain",
    )
    if version == "1.10.2":
        maybe(
            http_archive,
            name = "ninja_build_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "ce35865411f0490368a8fc383f29071de6690cbadc27704734978221f25e2bed",
            strip_prefix = "ninja-1.10.2",
            urls = [
                "https://github.com/ninja-build/ninja/archive/v1.10.2.tar.gz",
            ],
        )
        return

    fail("Unsupported ninja version: " + str(version))
