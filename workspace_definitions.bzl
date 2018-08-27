load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(":repositories.bzl", "repositories")
load(":install_ws_dependency.bzl", "install_ws_dependency")

def _platform_dependent_init_impl(rctx):
    host_os = _get_host_os(rctx)
    rctx.file("WORKSPACE", """workspace(name='foreign_cc_platform_utils')""")
    rctx.file("BUILD.bazel", "\n".join(
        [_shell_utils_text(rctx, host_os), _cmake_build_rule_text(rctx, host_os)],
    ))
    _create_os_description(rctx, host_os)

def _get_host_os(rctx):
    os_name = rctx.os.name.lower()
    is_win = os_name.find("windows") != -1
    is_osx = os_name.startswith("mac os")
    return {
        "is_unix": not is_win and not is_osx,
        "is_win": is_win,
        "is_osx": is_osx,
    }

def _create_os_description(rctx, host_os):
    rctx.file("host_os.bzl", "host_os = " + str(host_os) + "\n")

def _shell_utils_text(rctx, host_os):
    utils_name = "utils_unix.sh"
    if host_os["is_osx"]:
        utils_name = "utils_osx.sh"
    if host_os["is_win"]:
        utils_name = "utils_win.bat"
        fail("Not supported yet!")

    path = rctx.path(Label("//tools/build_defs:" + utils_name))
    rctx.template(utils_name, path, executable = True)

    return """
sh_library(
  name = "shell_utils",
  srcs = ["{}"],
  visibility = ["//visibility:public"]
)
""".format(utils_name)

def _cmake_build_rule_text(rctx, host_os):
    existing_cmake = rctx.which("cmake")
    is_ci = rctx.os.environ.get("CI")

    cmake_globals_text = ""
    cmake_text = ""

    # for now, do not try to build cmake from sources, rather fail fast
    if existing_cmake != None or existing_cmake == None and is_ci == None:
        cmake_globals_text = """
CMAKE_COMMAND="cmake"
CMAKE_DEPS=[]
        """
        cmake_text = """
sh_library(
  name = "cmake",
  visibility = ["//visibility:public"]
)
        """
    else:
        path_to_cmake_build = rctx.path(Label("//tools/build_defs:cmake_build.bzl"))
        rctx.template("cmake_build.bzl", path_to_cmake_build)

        path_to_detect_root = rctx.path(Label("//tools/build_defs:detect_root.bzl"))
        rctx.template("detect_root.bzl", path_to_detect_root)

        cmake_globals_text = """
CMAKE_COMMAND="$EXT_BUILD_DEPS/bin/cmake/bin/cmake"
CMAKE_DEPS=[Label("@foreign_cc_platform_utils//:cmake")]
"""

        cmake_text = """
sh_library(
  name = "cmake",
  srcs = [":cmake_externally_built"],
  visibility = ["//visibility:public"]
)

load("//:cmake_build.bzl", "cmake_tool")
cmake_tool(
  name = "cmake_externally_built",
  cmake_srcs = "@cmake//:all"
)
"""
    rctx.file("cmake_globals.bzl", cmake_globals_text)
    return cmake_text

_platform_dependent_init = repository_rule(
    implementation = _platform_dependent_init_impl,
)

def rules_foreign_cc_dependencies():
    repositories()
    _platform_dependent_init(name = "foreign_cc_platform_utils")
    install_ws_dependency(
        repo_name = "build_bazel_rules_apple",
        url = "https://github.com/bazelbuild/rules_apple/archive/0.7.0.tar.gz",
        strip_prefix = "rules_apple-0.7.0",
        init_file = "//apple:repositories.bzl",
        init_function = "apple_rules_dependencies",
    )
