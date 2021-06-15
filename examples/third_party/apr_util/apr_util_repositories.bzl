"""A module defining the third party dependency apr"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def apr_util_repositories():
    maybe(
        http_archive,
        name = "apr_util",
        build_file = Label("//apr_util:BUILD.apr_util.bazel"),
        sha256 = "b65e40713da57d004123b6319828be7f1273fbc6490e145874ee1177e112c459",
        strip_prefix = "apr-util-1.6.1",
        urls = [
            "https://mirror.bazel.build/www-us.apache.org/dist//apr/apr-util-1.6.1.tar.gz",
            "https://www-us.apache.org/dist//apr/apr-util-1.6.1.tar.gz",
        ],
    )
