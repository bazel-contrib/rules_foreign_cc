"""A module defining the third party dependency libsodium"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def libsodium_repositories():
    maybe(
        http_archive,
        name = "libsodium",
        sha256 = "6f504490b342a4f8a4c4a02fc9b866cbef8622d5df4e5452b46be121e46636c1",
        strip_prefix = "libsodium-1.0.18",
        urls = [
            "https://download.libsodium.org/libsodium/releases/libsodium-1.0.18.tar.gz",
        ],
        build_file = Label("//libsodium:BUILD.libsodium.bazel"),
    )
