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
    """Load all repositories needed for the targets of rules_foreign_cc_examples_third_party"""
    maybe(
        http_archive,
        name = "gmp",
        build_file_content = _ALL_CONTENT,
        strip_prefix = "gmp-6.2.1",
        urls = [
            "https://mirror.bazel.build/gmplib.org/download/gmp/gmp-6.2.1.tar.xz",
            "https://gmplib.org/download/gmp/gmp-6.2.1.tar.xz",
        ],
        sha256 = "fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2",
    )

    maybe(
        http_archive,
        name = "mpfr",
        build_file_content = _ALL_CONTENT,
        strip_prefix = "mpfr-4.1.0",
        urls = [
            "https://mirror.bazel.build/www.mpfr.org/mpfr-current/mpfr-4.1.0.tar.gz",
            "https://www.mpfr.org/mpfr-current/mpfr-4.1.0.tar.gz",
        ],
        sha256 = "3127fe813218f3a1f0adf4e8899de23df33b4cf4b4b3831a5314f78e65ffa2d6",
    )

    maybe(
        http_archive,
        name = "mpc",
        build_file_content = _ALL_CONTENT,
        strip_prefix = "mpc-1.1.0",
        urls = [
            "https://mirror.bazel.build/ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz",
            "https://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz",
        ],
        sha256 = "6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e",
    )
