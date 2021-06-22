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
        "@rules_foreign_cc//toolchains:built_cmake_toolchain",
    )
    if "3.20.4" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "87a4060298f2c6bb09d479de1400bc78195a5b55a65622a7dceeb3d1090a1b16",
            strip_prefix = "cmake-3.20.4",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.20.4/cmake-3.20.4.tar.gz",
            ],
        )
        return

    if "3.20.3" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "4d008ac3461e271fcfac26a05936f77fc7ab64402156fb371d41284851a651b8",
            strip_prefix = "cmake-3.20.3",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.20.3/cmake-3.20.3.tar.gz",
            ],
        )
        return

    if "3.20.2" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "aecf6ecb975179eb3bb6a4a50cae192d41e92b9372b02300f9e8f1d5f559544e",
            strip_prefix = "cmake-3.20.2",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.20.2/cmake-3.20.2.tar.gz",
            ],
        )
        return

    if "3.20.1" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "3f1808b9b00281df06c91dd7a021d7f52f724101000da7985a401678dfe035b0",
            strip_prefix = "cmake-3.20.1",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.20.1/cmake-3.20.1.tar.gz",
            ],
        )
        return

    if "3.20.0" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "9c06b2ddf7c337e31d8201f6ebcd3bba86a9a033976a9aee207fe0c6971f4755",
            strip_prefix = "cmake-3.20.0",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.20.0/cmake-3.20.0.tar.gz",
            ],
        )
        return

    if "3.19.7" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "58a15f0d56a0afccc3cc5371234fce73fcc6c8f9dbd775d898e510b83175588e",
            strip_prefix = "cmake-3.19.7",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.19.7/cmake-3.19.7.tar.gz",
            ],
        )
        return

    if "3.19.6" == version:
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
        "@rules_foreign_cc//toolchains:built_make_toolchain",
    )
    if version == "4.3":
        maybe(
            http_archive,
            name = "gnumake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "e05fdde47c5f7ca45cb697e973894ff4f5d79e13b750ed57d7b66d8defc78e19",
            strip_prefix = "make-4.3",
            urls = [
                "https://mirror.bazel.build/ftpmirror.gnu.org/gnu/make/make-4.3.tar.gz",
                "http://ftpmirror.gnu.org/gnu/make/make-4.3.tar.gz",
            ],
        )
        return

    fail("Unsupported make version: " + str(version))

def _ninja_toolchain(version):
    native.register_toolchains(
        "@rules_foreign_cc//toolchains:built_ninja_toolchain",
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
