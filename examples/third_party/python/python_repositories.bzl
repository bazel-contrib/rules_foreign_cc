"""A module defining the third party dependency Python"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

# buildifier: disable=unnamed-macro
def python_repositories():
    maybe(
        http_archive,
        name = "python2",
        build_file = Label("//python:BUILD.python2.bazel"),
        strip_prefix = "Python-2.7.9",
        urls = [
            "https://www.python.org/ftp/python/2.7.9/Python-2.7.9.tgz",
        ],
        sha256 = "c8bba33e66ac3201dabdc556f0ea7cfe6ac11946ec32d357c4c6f9b018c12c5b",
    )
    maybe(
        http_archive,
        name = "python3",
        build_file = Label("//python:BUILD.python3.bazel"),
        strip_prefix = "Python-3.9.3",
        urls = [
            "https://www.python.org/ftp/python/3.9.3/Python-3.9.3.tgz",
        ],
        sha256 = "3afeb61a45b5a2e6f1c0f621bd8cf925a4ff406099fdb3d8c97b993a5f43d048",
    )

    maybe(
        http_archive,
        name = "rules_python",
        sha256 = "778197e26c5fbeb07ac2a2c5ae405b30f6cb7ad1f5510ea6fdac03bded96cc6f",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_python/releases/download/0.2.0/rules_python-0.2.0.tar.gz",
            "https://github.com/bazelbuild/rules_python/releases/download/0.2.0/rules_python-0.2.0.tar.gz",
        ],
    )

    native.register_toolchains("@rules_foreign_cc_examples_third_party//python:python_toolchain")
