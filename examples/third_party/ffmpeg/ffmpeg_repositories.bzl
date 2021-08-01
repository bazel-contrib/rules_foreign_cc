"""A module defining the third party dependency ffmpeg"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def ffmpeg_repositories():
    maybe(
        http_archive,
        name = "ffmpeg",
        build_file = Label("//ffmpeg:BUILD.ffmpeg.bazel"),
        strip_prefix = "ffmpeg-4.4",
        urls = [
            "https://ffmpeg.org/releases/ffmpeg-4.4.tar.gz",
        ],
    )
