load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

all_content = """filegroup(name = "all", srcs = glob(["**"]), visibility = ["//visibility:public"])"""

def include_examples_repositories():
    http_archive(
        name = "libevent",
        build_file_content = all_content,
        strip_prefix = "libevent-2.1.8-stable",
        urls = [
            "https://mirror.bazel.build/github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz",
            "https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz",
        ],
    )

    http_archive(
        name = "zlib",
        build_file_content = all_content,
        sha256 = "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1",
        strip_prefix = "zlib-1.2.11",
        urls = [
            "https://mirror.bazel.build/zlib.net/zlib-1.2.11.tar.gz",
            "https://zlib.net/zlib-1.2.11.tar.gz",
        ],
    )

    http_archive(
        name = "libpng",
        build_file_content = all_content,
        sha256 = "2f1e960d92ce3b3abd03d06dfec9637dfbd22febf107a536b44f7a47c60659f6",
        strip_prefix = "libpng-1.6.34",
        urls = [
            "https://mirror.bazel.build/ftp-osl.osuosl.org/pub/libpng/src/libpng16/libpng-1.6.34.tar.xz",
            "http://ftp-osl.osuosl.org/pub/libpng/src/libpng16/libpng-1.6.34.tar.xz",
        ],
    )

    http_archive(
        name = "freetype",
        build_file_content = all_content,
        sha256 = "e6ffba3c8cef93f557d1f767d7bc3dee860ac7a3aaff588a521e081bc36f4c8a",
        strip_prefix = "freetype-2.9",
        urls = [
            "https://mirror.bazel.build/download.savannah.gnu.org/releases/freetype/freetype-2.9.tar.bz2",
            "https://download.savannah.gnu.org/releases/freetype/freetype-2.9.tar.bz2",
        ],
    )

    http_archive(
        name = "libgd",
        build_file_content = all_content,
        sha256 = "8c302ccbf467faec732f0741a859eef4ecae22fea2d2ab87467be940842bde51",
        strip_prefix = "libgd-2.2.5",
        urls = [
            "https://mirror.bazel.build/github.com/libgd/libgd/releases/download/gd-2.2.5/libgd-2.2.5.tar.xz",
            "https://github.com/libgd/libgd/releases/download/gd-2.2.5/libgd-2.2.5.tar.xz",
        ],
    )

    http_archive(
        name = "pybind11",
        build_file_content = all_content,
        strip_prefix = "pybind11-2.2.3",
        urls = [
            "https://mirror.bazel.build/github.com/pybind/pybind11/archive/v2.2.3.tar.gz",
            "https://github.com/pybind/pybind11/archive/v2.2.3.tar.gz",
        ],
    )

    http_archive(
        name = "cares",
        build_file_content = all_content,
        sha256 = "62dd12f0557918f89ad6f5b759f0bf4727174ae9979499f5452c02be38d9d3e8",
        strip_prefix = "c-ares-cares-1_14_0",
        urls = [
            "https://mirror.bazel.build/github.com/c-ares/c-ares/archive/cares-1_14_0.tar.gz",
            "https://github.com/c-ares/c-ares/archive/cares-1_14_0.tar.gz",
        ],
    )

    http_archive(
        name = "nghttp2",
        build_file_content = all_content,
        patch_args = ["-p1"],
        patch_cmds = ["find . -name '*.sh' -exec sed -i.orig '1s|#!/usr/bin/env sh\\$|/bin/sh\\$|' {} +"],
        patches = ["@rules_foreign_cc_tests//:nghttp2.patch"],
        strip_prefix = "nghttp2-e5b3f9addd49bca27e2f99c5c65a564eb5c0cf6d",
        urls = [
            "https://mirror.bazel.build/github.com/nghttp2/nghttp2/archive/e5b3f9addd49bca27e2f99c5c65a564eb5c0cf6d.tar.gz",
            "https://github.com/nghttp2/nghttp2/archive/e5b3f9addd49bca27e2f99c5c65a564eb5c0cf6d.tar.gz",
        ],
    )

    http_archive(
        name = "eigen",
        build_file_content = all_content,
        strip_prefix = "eigen-git-mirror-3.3.5",
        urls = [
            "https://mirror.bazel.build/github.com/eigenteam/eigen-git-mirror/archive/3.3.5.tar.gz",
            "https://github.com/eigenteam/eigen-git-mirror/archive/3.3.5.tar.gz",
        ],
    )

    http_archive(
        name = "openblas",
        build_file_content = all_content,
        strip_prefix = "OpenBLAS-0.3.2",
        urls = [
            "https://mirror.bazel.build/github.com/xianyi/OpenBLAS/archive/v0.3.2.tar.gz",
            "https://github.com/xianyi/OpenBLAS/archive/v0.3.2.tar.gz",
        ],
    )

    http_archive(
        name = "flann",
        build_file_content = all_content,
        strip_prefix = "flann-1.9.1",
        urls = [
            "https://mirror.bazel.build/github.com/mariusmuja/flann/archive/1.9.1.tar.gz",
            "https://github.com/mariusmuja/flann/archive/1.9.1.tar.gz",
        ],
    )

    http_archive(
        name = "pcl",
        build_file_content = all_content,
        strip_prefix = "pcl-pcl-1.8.1",
        urls = [
            "https://mirror.bazel.build/github.com/PointCloudLibrary/pcl/archive/pcl-1.8.1.tar.gz",
            "https://github.com/PointCloudLibrary/pcl/archive/pcl-1.8.1.tar.gz",
        ],
    )

    http_archive(
        name = "boost",
        build_file_content = all_content,
        strip_prefix = "boost_1_68_0",
        sha256 = "da3411ea45622579d419bfda66f45cd0f8c32a181d84adfa936f5688388995cf",
        urls = [
            "https://mirror.bazel.build/dl.bintray.com/boostorg/release/1.68.0/source/boost_1_68_0.tar.gz",
            "https://dl.bintray.com/boostorg/release/1.68.0/source/boost_1_68_0.tar.gz",
        ],
    )

    http_archive(
        name = "bison",
        build_file_content = all_content,
        strip_prefix = "bison-3.3",
        urls = [
            "https://mirror.bazel.build/ftp.gnu.org/gnu/bison/bison-3.3.tar.gz",
            "http://ftp.gnu.org/gnu/bison/bison-3.3.tar.gz",
        ],
    )

    http_archive(
        name = "apache_httpd",
        build_file_content = all_content,
        strip_prefix = "httpd-2.4.39",
        urls = [
            "https://mirror.bazel.build/www-us.apache.org/dist/httpd/httpd-2.4.39.tar.gz",
            "https://www-us.apache.org/dist/httpd/httpd-2.4.39.tar.gz",
        ],
    )

    http_archive(
        name = "pcre",
        build_file_content = all_content,
        strip_prefix = "pcre-8.43",
        urls = [
            "https://mirror.bazel.build/ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz",
            "https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz",
        ],
    )

    http_archive(
        name = "apr",
        build_file_content = all_content,
        strip_prefix = "apr-1.6.5",
        urls = [
            "https://mirror.bazel.build/www-eu.apache.org/dist//apr/apr-1.6.5.tar.gz",
            "https://www-eu.apache.org/dist//apr/apr-1.6.5.tar.gz",
        ],
    )

    http_archive(
        name = "apr_util",
        build_file_content = all_content,
        strip_prefix = "apr-util-1.6.1",
        urls = [
            "https://mirror.bazel.build/www-us.apache.org/dist//apr/apr-util-1.6.1.tar.gz",
            "https://www-us.apache.org/dist//apr/apr-util-1.6.1.tar.gz",
        ],
    )

    http_archive(
        name = "cmake_hello_world_variant_src",
        build_file_content = """filegroup(name = "all", srcs = glob(["**"]), visibility = ["//visibility:public"])""",
        strip_prefix = "cmake-hello-world-master",
        urls = [
            "https://mirror.bazel.build/github.com/jameskbride/cmake-hello-world/archive/master.zip",
            "https://github.com/jameskbride/cmake-hello-world/archive/master.zip",
        ],
        sha256 = "d613cf222bbb05b8cff7a1c03c37345ed33744a4ebaf3a8bfd5f56a76e25ca08",
    )

    http_archive(
        name = "gmp",
        build_file_content = all_content,
        strip_prefix = "gmp-6.2.0",
        urls = [
            "https://mirror.bazel.build/gmplib.org/download/gmp/gmp-6.2.0.tar.gz",
            "https://gmplib.org/download/gmp/gmp-6.2.0.tar.gz",
        ],
        sha256 = "cadd49052b740ccc3d8075c24ceaefbe5128d44246d91d0ecc818b2f78b0ec9c",
    )

    http_archive(
        name = "mpfr",
        build_file_content = all_content,
        strip_prefix = "mpfr-4.0.2",
        urls = [
            "https://mirror.bazel.build/www.mpfr.org/mpfr-current/mpfr-4.0.2.tar.gz",
            "https://www.mpfr.org/mpfr-current/mpfr-4.0.2.tar.gz",
        ],
        sha256 = "ae26cace63a498f07047a784cd3b0e4d010b44d2b193bab82af693de57a19a78",
    )

    http_archive(
        name = "mpc",
        build_file_content = all_content,
        strip_prefix = "mpc-1.1.0",
        urls = [
            "https://mirror.bazel.build/ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz",
            "https://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz",
        ],
        sha256 = "6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e",
    )

    http_archive(
        name = "libunwind",
        build_file_content = all_content,
        strip_prefix = "libunwind-9165d2a150d707d3037c2045f2cdc0fabd5fee98",
        urls = [
            "https://mirror.bazel.build/github.com/libunwind/libunwind/archive/9165d2a150d707d3037c2045f2cdc0fabd5fee98.zip",
            "https://github.com/libunwind/libunwind/archive/9165d2a150d707d3037c2045f2cdc0fabd5fee98.zip",
        ],
        sha256 = "f83c604cde80a49af91345a1ff3f4558958202989fb768e6508963e24ea2524c",
    )
