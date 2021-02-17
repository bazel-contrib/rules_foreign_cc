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
    """Load all repositories needed for apache_httpd"""

    maybe(
        http_archive,
        name = "apache_httpd",
        build_file_content = _ALL_CONTENT,
        strip_prefix = "httpd-2.4.39",
        urls = [
            "https://mirror.bazel.build/www-us.apache.org/dist/httpd/httpd-2.4.39.tar.gz",
            "https://www-us.apache.org/dist/httpd/httpd-2.4.39.tar.gz",
        ],
        sha256 = "8b95fe249f3a6c50aad3ca125eef3e02d619116cde242e1bc3c266b7b5c37c30",
    )

    maybe(
        http_archive,
        name = "pcre",
        build_file_content = _ALL_CONTENT,
        strip_prefix = "pcre-8.43",
        urls = [
            "https://mirror.bazel.build/ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz",
            "https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz",
        ],
        sha256 = "0b8e7465dc5e98c757cc3650a20a7843ee4c3edf50aaf60bb33fd879690d2c73",
    )

    maybe(
        http_archive,
        name = "apr",
        build_file_content = _ALL_CONTENT,
        strip_prefix = "apr-1.6.5",
        urls = [
            "https://mirror.bazel.build/www-eu.apache.org/dist//apr/apr-1.6.5.tar.gz",
            "https://www-eu.apache.org/dist//apr/apr-1.6.5.tar.gz",
        ],
        sha256 = "70dcf9102066a2ff2ffc47e93c289c8e54c95d8dda23b503f9e61bb0cbd2d105",
    )

    maybe(
        http_archive,
        name = "apr_util",
        build_file_content = _ALL_CONTENT,
        strip_prefix = "apr-util-1.6.1",
        sha256 = "b65e40713da57d004123b6319828be7f1273fbc6490e145874ee1177e112c459",
        urls = [
            "https://mirror.bazel.build/www-us.apache.org/dist//apr/apr-util-1.6.1.tar.gz",
            "https://www-us.apache.org/dist//apr/apr-util-1.6.1.tar.gz",
        ],
    )
