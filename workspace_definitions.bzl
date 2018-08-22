load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _define_shell_utils_impl(rctx):
    os_name = rctx.os.name.lower()
    utils_name = "utils_unix.sh"
    if os_name.startswith("mac os"):
        utils_name = "utils_osx.sh"
    if os_name.find("windows") != -1:
        utils_name = "utils_win.bat"
        fail("Not supported yet!")
    rctx.file("WORKSPACE", "workspace(name='foreign_cc_platform_utils')")
    rctx.file("BUILD.bazel", """
sh_library(
  name = "shell_utils",
  srcs = ["{}"],
  visibility = ["//visibility:public"]
)
""".format(utils_name))
    path = rctx.path(Label("//tools/build_defs:" + utils_name))
    rctx.template(utils_name, path, executable = True)

_define_shell_utils = repository_rule(
    implementation = _define_shell_utils_impl,
)

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

    _define_shell_utils(name = "foreign_cc_platform_utils")
