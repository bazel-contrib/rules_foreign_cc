"""A module defining the third party dependency pkg-config"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def pkgconfig_repositories():
    maybe(
        http_archive,
        name = "pkg-config",
        build_file = Label("//third_party/pkg-config:BUILD.pkg-config.bazel"),
        strip_prefix = "pkg-config-0.29.2",
        urls = ["https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz"],
    )
