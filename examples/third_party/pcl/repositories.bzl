# buildifier: disable=module-docstring
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//boost:repositories.bzl", boost_repositories = "repositories")

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
        name = "pcl",
        build_file_content = _ALL_CONTENT,
        strip_prefix = "pcl-pcl-1.8.1",
        urls = [
            "https://mirror.bazel.build/github.com/PointCloudLibrary/pcl/archive/pcl-1.8.1.tar.gz",
            "https://github.com/PointCloudLibrary/pcl/archive/pcl-1.8.1.tar.gz",
        ],
        sha256 = "5a102a2fbe2ba77c775bf92c4a5d2e3d8170be53a68c3a76cfc72434ff7b9783",
    )

    maybe(
        http_archive,
        name = "eigen",
        build_file_content = _ALL_CONTENT,
        strip_prefix = "eigen-git-mirror-3.3.5",
        urls = [
            "https://mirror.bazel.build/github.com/eigenteam/eigen-git-mirror/archive/3.3.5.tar.gz",
            "https://github.com/eigenteam/eigen-git-mirror/archive/3.3.5.tar.gz",
        ],
        sha256 = "992855522dfdd0dea74d903dcd082cdb01c1ae72be5145e2fe646a0892989e43",
    )

    maybe(
        http_archive,
        name = "openblas",
        build_file_content = _ALL_CONTENT,
        strip_prefix = "OpenBLAS-0.3.2",
        urls = [
            "https://mirror.bazel.build/github.com/xianyi/OpenBLAS/archive/v0.3.2.tar.gz",
            "https://github.com/xianyi/OpenBLAS/archive/v0.3.2.tar.gz",
        ],
        sha256 = "e8ba64f6b103c511ae13736100347deb7121ba9b41ba82052b1a018a65c0cb15",
    )

    maybe(
        http_archive,
        name = "flann",
        build_file_content = _ALL_CONTENT,
        strip_prefix = "flann-1.9.1",
        urls = [
            "https://mirror.bazel.build/github.com/mariusmuja/flann/archive/1.9.1.tar.gz",
            "https://github.com/mariusmuja/flann/archive/1.9.1.tar.gz",
        ],
        sha256 = "b23b5f4e71139faa3bcb39e6bbcc76967fbaf308c4ee9d4f5bfbeceaa76cc5d3",
    )

    boost_repositories()
