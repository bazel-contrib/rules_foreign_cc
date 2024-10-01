"""A module defining the third party dependency ffmpeg"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

# buildifier: disable=function-docstring
def ffmpeg_repositories():
    maybe(
        http_archive,
        name = "ffmpeg",
        build_file = Label("//ffmpeg:BUILD.ffmpeg.bazel"),
        strip_prefix = "FFmpeg-n7.0.2",
        urls = ["https://github.com/FFmpeg/FFmpeg/archive/refs/tags/n7.0.2.tar.gz"],
        integrity = "sha256-XrRtGNZkoMyt97Ct7gO9O3+nKJPWZ/NsaeICqAfm1TM=",
    )

    YASM_COMMMIT = "121ab150b3577b666c79a79f4a511798d7ad2432"
    maybe(
        http_archive,
        name = "yasm",
        build_file = Label("//ffmpeg:BUILD.yasm.bazel"),
        strip_prefix = "yasm-%s" % YASM_COMMMIT,
        urls = ["https://github.com/yasm/yasm/archive/%s.tar.gz" % YASM_COMMMIT],
        integrity = "sha256-PfFT8fuUUTq5LLHaf7g3ejFW93TWi8z070IJRzqqG7Y=",
    )

    LIBYUV_COMMIT = "77f3acade492a41a11a07a55b58a6f8180b898eb"
    maybe(
        http_archive,
        name = "libyuv",
        build_file = Label("//ffmpeg:BUILD.libyuv.bazel"),
        sha256 = "6c898607e2ec3a38cd88f210bd6eb17f0be9e89274d9b5b1e5a83ed29219d3a8",
        strip_prefix = "libyuv-%s" % LIBYUV_COMMIT,
        urls = ["https://github.com/lemenkov/libyuv/archive/%s.tar.gz" % LIBYUV_COMMIT],
    )

    maybe(
        http_archive,
        name = "libvpx",
        build_file = Label("//ffmpeg:BUILD.libvpx.bazel"),
        sha256 = "901747254d80a7937c933d03bd7c5d41e8e6c883e0665fadcb172542167c7977",
        strip_prefix = "libvpx-1.14.1",
        urls = ["https://github.com/webmproject/libvpx/archive/refs/tags/v1.14.1.tar.gz"],
    )

    maybe(
        http_archive,
        name = "libaom",
        build_file = Label("//ffmpeg:BUILD.libaom.bazel"),
        sha256 = "d1f2bd34b61ff1e58e72946825accd5f5fc23212055bf78161f6fa5b6d93b925",
        strip_prefix = "aom-3.10.0",
        urls = ["https://github.com/jbeich/aom/archive/refs/tags/v3.10.0.tar.gz"],
    )

    maybe(
        http_archive,
        name = "libsvtav1",
        build_file = Label("//ffmpeg:BUILD.libsvtav1.bazel"),
        strip_prefix = "SVT-AV1-v2.2.1",
        urls = ["https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v2.2.1/SVT-AV1-v2.2.1.tar.gz"],
        integrity = "sha256-0CtUaFVC3gI2vOS+G1CRKrpor/mXxDs1DYSlGN8M9OU=",
    )

    maybe(
        http_archive,
        name = "libdav1d",
        build_file = Label("//ffmpeg:BUILD.libdav1d.bazel"),
        strip_prefix = "dav1d-1.4.3",
        urls = ["https://code.videolan.org/videolan/dav1d/-/archive/1.4.3/dav1d-1.4.3.tar.gz"],
        integrity = "sha256-iKAj5Y2VXgiG+vSccpQODpCRSpSKjmDBMmzj4J56YJk=",
    )
