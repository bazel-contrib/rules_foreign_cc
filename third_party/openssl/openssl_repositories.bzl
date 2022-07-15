"""A module defining the third party dependency OpenSSL"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def openssl_repositories():
    maybe(
        http_archive,
        name = "openssl",
        build_file = Label("//third_party/openssl:BUILD.openssl.bazel"),
        sha256 = "0f745b85519aab2ce444a3dcada93311ba926aea2899596d01e7f948dbd99981",
        strip_prefix = "openssl-OpenSSL_1_1_1o",
        urls = [
            "https://mirror.bazel.build/www.openssl.org/source/openssl-1.1.1o.tar.gz",
            "https://www.openssl.org/source/openssl-1.1.1o.tar.gz",
            "https://github.com/openssl/openssl/archive/OpenSSL_1_1_1o.tar.gz",
        ],
    )

    maybe(
        http_archive,
        name = "nasm",
        build_file = Label("//third_party/openssl:BUILD.nasm.bazel"),
        sha256 = "f5c93c146f52b4f1664fa3ce6579f961a910e869ab0dae431bd871bdd2584ef2",
        strip_prefix = "nasm-2.15.05",
        urls = [
            "https://mirror.bazel.build/www.nasm.us/pub/nasm/releasebuilds/2.15.05/win64/nasm-2.15.05-win64.zip",
            "https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/win64/nasm-2.15.05-win64.zip",
        ],
    )

    maybe(
        http_archive,
        name = "rules_perl",
        strip_prefix = "rules_perl-43d2db0aafe595fe0ac61b808c9c13ea9769ce03",
        urls = [
            "https://github.com/bazelbuild/rules_perl/archive/43d2db0aafe595fe0ac61b808c9c13ea9769ce03.tar.gz",
        ],
    )
