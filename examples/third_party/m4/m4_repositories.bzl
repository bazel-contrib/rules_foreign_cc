# buildifier: disable=module-docstring
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def m4_repositories():
    """Load all repositories needed for m4"""

    maybe(
        http_archive,
        name = "m4",
        build_file = Label("//m4:BUILD.m4.bazel"),
        strip_prefix = "m4-1.4.18b",
        urls = [
            "https://alpha.gnu.org/gnu/m4/m4-1.4.18b.tar.xz",
        ],
        sha256 = "0aaf6b798e08a1b76966ec0adf678253f86e40b09baa534e1e63655882632db0",
    )
