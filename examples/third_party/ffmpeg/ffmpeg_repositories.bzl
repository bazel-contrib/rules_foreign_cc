"""A module defining the third party dependency ffmpeg"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def ffmpeg_repositories():
    maybe(
        http_archive,
        name = "ffmpeg",
        build_file = Label("//ffmpeg:BUILD.ffmpeg.bazel"),
        sha256 = "a4abede145de22eaf233baa1726e38e137f5698d9edd61b5763cd02b883f3c7c",
        strip_prefix = "ffmpeg-4.4",
        urls = [
            "https://ffmpeg.org/releases/ffmpeg-4.4.tar.gz",
        ],
    )
