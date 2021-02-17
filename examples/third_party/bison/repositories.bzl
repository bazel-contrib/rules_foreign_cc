# buildifier: disable=module-docstring
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

_ALL_CONTENT = """\
filegroup(
    name = "all", 
    srcs = glob(["**"]), 
    visibility = ["//visibility:public"],
)
"""

def repositories():
    """Load all repositories needed for bison"""

    maybe(
        http_archive,
        name = "bison",
        build_file_content = _ALL_CONTENT,
        strip_prefix = "bison-3.3",
        urls = [
            "https://mirror.bazel.build/ftp.gnu.org/gnu/bison/bison-3.3.tar.gz",
            "http://ftp.gnu.org/gnu/bison/bison-3.3.tar.gz",
        ],
        sha256 = "fdeafb7fffade05604a61e66b8c040af4b2b5cbb1021dcfe498ed657ac970efd",
    )
