load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def rules_foreign_cc_dependencies():
    _all_content = """filegroup(name = "all", srcs = glob(["**"]), visibility = ["//visibility:public"])"""

    http_archive(
        name = "bazel_skylib",
        build_file_content = _all_content,
        sha256 = "b5f6abe419da897b7901f90cbab08af958b97a8f3575b0d3dd062ac7ce78541f",
        strip_prefix = "bazel-skylib-0.5.0",
        type = "tar.gz",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/archive/0.5.0.tar.gz",
        ],
    )
