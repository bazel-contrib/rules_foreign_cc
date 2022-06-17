"""A module defining the third party dependency Python"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

# buildifier: disable=unnamed-macro
def python_repositories():
    maybe(
        http_archive,
        name = "python2",
        build_file = Label("//python:BUILD.python2.bazel"),
        strip_prefix = "Python-2.7.18",
        urls = [
            "https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz",
        ],
        sha256 = "da3080e3b488f648a3d7a4560ddee895284c3380b11d6de75edb986526b9a814",
    )
    maybe(
        http_archive,
        name = "python3",
        build_file = Label("//python:BUILD.python3.bazel"),
        strip_prefix = "Python-3.10.1",
        urls = [
            "https://www.python.org/ftp/python/3.10.1/Python-3.10.1.tgz",
        ],
        sha256 = "b76117670e7c5064344b9c138e141a377e686b9063f3a8a620ff674fa8ec90d3",
    )

    maybe(
        http_archive,
        name = "rules_python",
        urls = [
            "https://github.com/bazelbuild/rules_python/releases/download/0.5.0/rules_python-0.5.0.tar.gz",
        ],
        sha256 = "cd6730ed53a002c56ce4e2f396ba3b3be262fd7cb68339f0377a45e8227fe332",
    )

    native.register_toolchains("@rules_foreign_cc_examples_third_party//python:python_toolchain")
