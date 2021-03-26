"""A module defining the third party dependency iconv"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def iconv_repositories():
    maybe(
        http_archive,
        name = "iconv",
        urls = [
            "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz",
        ],
        type = "tar.gz",
        sha256 = "e6a1b1b589654277ee790cce3734f07876ac4ccfaecbee8afa0b649cf529cc04",
        strip_prefix = "libiconv-1.16",
        build_file = Label("//iconv:BUILD.iconv.bazel"),
    )

    maybe(
        http_archive,
        name = "iconv_macos",
        urls = [
            "https://opensource.apple.com/tarballs/libiconv/libiconv-59.tar.gz",
        ],
        type = "tar.gz",
        sha256 = "f7729999a9f2adc8c158012bc4bc8d69bea5dec88c8203cdd62067f91ed60b43",
        strip_prefix = "libiconv-59/libiconv",
        build_file = Label("//iconv:BUILD.iconv.macos.bazel"),
    )
