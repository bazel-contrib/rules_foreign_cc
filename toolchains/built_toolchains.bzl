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

_CMAKE_SRCS = {
    "3.21.0": [["https://github.com/Kitware/CMake/releases/download/v3.21.0/cmake-3.21.0.tar.gz"], "cmake-3.21.0", "4a42d56449a51f4d3809ab4d3b61fd4a96a469e56266e896ce1009b5768bd2ab"],
    "3.21.1": [["https://github.com/Kitware/CMake/releases/download/v3.21.1/cmake-3.21.1.tar.gz"], "cmake-3.21.1", "fac3915171d4dff25913975d712f76e69aef44bf738ba7b976793a458b4cfed4"],
    "3.21.2": [["https://github.com/Kitware/CMake/releases/download/v3.21.2/cmake-3.21.2.tar.gz"], "cmake-3.21.2", "94275e0b61c84bb42710f5320a23c6dcb2c6ee032ae7d2a616f53f68b3d21659"],
    "3.21.3": [["https://github.com/Kitware/CMake/releases/download/v3.21.3/cmake-3.21.3.tar.gz"], "cmake-3.21.3", "d14d06df4265134ee42c4d50f5a60cb8b471b7b6a47da8e5d914d49dd783794f"],
    "3.21.4": [["https://github.com/Kitware/CMake/releases/download/v3.21.4/cmake-3.21.4.tar.gz"], "cmake-3.21.4", "d9570a95c215f4c9886dd0f0564ca4ef8d18c30750f157238ea12669c2985978"],
    "3.21.5": [["https://github.com/Kitware/CMake/releases/download/v3.21.5/cmake-3.21.5.tar.gz"], "cmake-3.21.5", "c73587b5ab827d56c09f0a1e256b12743ff200495e31fc9686f2b9dc8a28897f"],
    "3.22.0": [["https://github.com/Kitware/CMake/releases/download/v3.22.0/cmake-3.22.0.tar.gz"], "cmake-3.22.0", "998c7ba34778d2dfdb3df8a695469e24b11e2bfa21fbe41b361a3f45e1c9345e"],
    "3.22.1": [["https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1.tar.gz"], "cmake-3.22.1", "0e998229549d7b3f368703d20e248e7ee1f853910d42704aa87918c213ea82c0"],
    "3.22.2": [["https://github.com/Kitware/CMake/releases/download/v3.22.2/cmake-3.22.2.tar.gz"], "cmake-3.22.2", "3c1c478b9650b107d452c5bd545c72e2fad4e37c09b89a1984b9a2f46df6aced"],
    "3.22.3": [["https://github.com/Kitware/CMake/releases/download/v3.22.3/cmake-3.22.3.tar.gz"], "cmake-3.22.3", "9f8469166f94553b6978a16ee29227ec49a2eb5ceb608275dec40d8ae0d1b5a0"],
    "3.22.4": [["https://github.com/Kitware/CMake/releases/download/v3.22.4/cmake-3.22.4.tar.gz"], "cmake-3.22.4", "5c55d0b0bc4c191549e3502b8f99a4fe892077611df22b4178cc020626e22a47"],
    "3.23.1": [["https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1.tar.gz"], "cmake-3.23.1", "33fd10a8ec687a4d0d5b42473f10459bb92b3ae7def2b745dc10b192760869f3"],
    "3.23.2": [["https://github.com/Kitware/CMake/releases/download/v3.23.2/cmake-3.23.2.tar.gz"], "cmake-3.23.2", "f316b40053466f9a416adf981efda41b160ca859e97f6a484b447ea299ff26aa"],
}

# buildifier: disable=unnamed-macro
def built_toolchains(cmake_version, make_version, ninja_version, register_toolchains):
    """Register toolchains for built tools that will be built from source"""
    _cmake_toolchain(cmake_version, register_toolchains)
    _make_toolchain(make_version, register_toolchains)
    _ninja_toolchain(ninja_version, register_toolchains)

def _cmake_toolchain(version, register_toolchains):
    if register_toolchains:
        native.register_toolchains(
            "@rules_foreign_cc//toolchains:built_cmake_toolchain",
        )

    if _CMAKE_SRCS.get(version):
        cmake_meta = _CMAKE_SRCS[version]
        urls = cmake_meta[0]
        prefix = cmake_meta[1]
        sha256 = cmake_meta[2]
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = sha256,
            strip_prefix = prefix,
            urls = urls,
        )
        return

    if "3.20.5" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "12c8040ef5c6f1bc5b8868cede16bb7926c18980f59779e299ab52cbc6f15bb0",
            strip_prefix = "cmake-3.20.5",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.20.5/cmake-3.20.5.tar.gz",
            ],
        )
        return

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

    if "3.18.6" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "124f571ab70332da97a173cb794dfa09a5b20ccbb80a08e56570a500f47b6600",
            strip_prefix = "cmake-3.18.6",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.18.6/cmake-3.18.6.tar.gz",
            ],
        )
        return

    if "3.17.5" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "8c3083d98fd93c1228d5e4e40dbff2dd88f4f7b73b9fa24a2938627b8bc28f1a",
            strip_prefix = "cmake-3.17.5",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.17.5/cmake-3.17.5.tar.gz",
            ],
        )
        return

    if "3.16.9" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "1708361827a5a0de37d55f5c9698004c035abb1de6120a376d5d59a81630191f",
            strip_prefix = "cmake-3.16.9",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.16.9/cmake-3.16.9.tar.gz",
            ],
        )
        return

    if "3.15.7" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "71999d8a14c9b51708847371250a61533439a7331eb7702ac105cfb3cb1be54b",
            strip_prefix = "cmake-3.15.7",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.15.7/cmake-3.15.7.tar.gz",
            ],
        )
        return

    if "3.14.7" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "9221993e0af3e6d10124d840ff24f5b2f3b884416fca04d3312cb0388dec1385",
            strip_prefix = "cmake-3.14.7",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.14.7/cmake-3.14.7.tar.gz",
            ],
        )
        return

    if "3.13.5" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "526db6a4b47772d1943b2f86de693e712f9dacf3d7c13b19197c9bef133766a5",
            strip_prefix = "cmake-3.13.5",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.13.5/cmake-3.13.5.tar.gz",
            ],
        )
        return

    if "3.12.4" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "5255584bfd043eb717562cff8942d472f1c0e4679c4941d84baadaa9b28e3194",
            strip_prefix = "cmake-3.12.4",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.12.4/cmake-3.12.4.tar.gz",
            ],
        )
        return

    if "3.11.4" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "8f864e9f78917de3e1483e256270daabc4a321741592c5b36af028e72bff87f5",
            strip_prefix = "cmake-3.11.4",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.11.4/cmake-3.11.4.tar.gz",
            ],
        )
        return

    if "3.10.3" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "0c3a1dcf0be03e40cf4f341dda79c96ffb6c35ae35f2f911845b72dab3559cf8",
            strip_prefix = "cmake-3.10.3",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.10.3/cmake-3.10.3.tar.gz",
            ],
        )
        return

    if "3.9.6" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "7410851a783a41b521214ad987bb534a7e4a65e059651a2514e6ebfc8f46b218",
            strip_prefix = "cmake-3.9.6",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.9.6/cmake-3.9.6.tar.gz",
            ],
        )
        return

    if "3.8.2" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "da3072794eb4c09f2d782fcee043847b99bb4cf8d4573978d9b2024214d6e92d",
            strip_prefix = "cmake-3.8.2",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.8.2/cmake-3.8.2.tar.gz",
            ],
        )
        return

    if "3.7.2" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "dc1246c4e6d168ea4d6e042cfba577c1acd65feea27e56f5ff37df920c30cae0",
            strip_prefix = "cmake-3.7.2",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.7.2/cmake-3.7.2.tar.gz",
            ],
        )
        return

    if "3.6.3" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "7d73ee4fae572eb2d7cd3feb48971aea903bb30a20ea5ae8b4da826d8ccad5fe",
            strip_prefix = "cmake-3.6.3",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.6.3/cmake-3.6.3.tar.gz",
            ],
        )
        return

    if "3.5.2" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "92d8410d3d981bb881dfff2aed466da55a58d34c7390d50449aa59b32bb5e62a",
            strip_prefix = "cmake-3.5.2",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.5.2/cmake-3.5.2.tar.gz",
            ],
        )
        return

    if "3.4.3" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "b73f8c1029611df7ed81796bf5ca8ba0ef41c6761132340c73ffe42704f980fa",
            strip_prefix = "cmake-3.4.3",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.4.3/cmake-3.4.3.tar.gz",
            ],
        )
        return

    if "3.3.2" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "e75a178d6ebf182b048ebfe6e0657c49f0dc109779170bad7ffcb17463f2fc22",
            strip_prefix = "cmake-3.3.2",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.3.2/cmake-3.3.2.tar.gz",
            ],
        )
        return

    if "3.2.3" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "a1ebcaf6d288eb4c966714ea457e3b9677cdfde78820d0f088712d7320850297",
            strip_prefix = "cmake-3.2.3",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.2.3/cmake-3.2.3.tar.gz",
            ],
        )
        return

    if "3.1.3" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "45f4d3fa8a2f61cc092ae461aac4cac1bab4ac6706f98274ea7f314dd315c6d0",
            strip_prefix = "cmake-3.1.3",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.1.3/cmake-3.1.3.tar.gz",
            ],
        )
        return

    if "3.0.2" == version:
        maybe(
            http_archive,
            name = "cmake_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "6b4ea61eadbbd9bec0ccb383c29d1f4496eacc121ef7acf37c7a24777805693e",
            strip_prefix = "cmake-3.0.2",
            urls = [
                "https://github.com/Kitware/CMake/releases/download/v3.0.2/cmake-3.0.2.tar.gz",
            ],
        )
        return

    fail("Unsupported cmake version: " + str(version))

def _make_toolchain(version, register_toolchains):
    if register_toolchains:
        native.register_toolchains(
            "@rules_foreign_cc//toolchains:built_make_toolchain",
        )
    if version == "4.3":
        maybe(
            http_archive,
            name = "gnumake_src",
            build_file_content = _ALL_CONTENT,
            patches = [Label("//toolchains:make-reproducible-bootstrap.patch")],
            sha256 = "e05fdde47c5f7ca45cb697e973894ff4f5d79e13b750ed57d7b66d8defc78e19",
            strip_prefix = "make-4.3",
            urls = [
                "https://mirror.bazel.build/ftpmirror.gnu.org/gnu/make/make-4.3.tar.gz",
                "http://ftpmirror.gnu.org/gnu/make/make-4.3.tar.gz",
            ],
        )
        return

    fail("Unsupported make version: " + str(version))

def _ninja_toolchain(version, register_toolchains):
    if register_toolchains:
        native.register_toolchains(
            "@rules_foreign_cc//toolchains:built_ninja_toolchain",
        )
    if version == "1.11.0":
        maybe(
            http_archive,
            name = "ninja_build_src",
            build_file_content = _ALL_CONTENT,
            sha256 = "3c6ba2e66400fe3f1ae83deb4b235faf3137ec20bd5b08c29bfc368db143e4c6",
            strip_prefix = "ninja-1.11.0",
            urls = [
                "https://github.com/ninja-build/ninja/archive/v1.11.0.tar.gz",
            ],
        )
        return
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
