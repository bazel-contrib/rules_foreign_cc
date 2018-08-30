load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//workspace:repositories.bzl", "repositories")
load("//workspace:os_info.bzl", "get_os_info")

def _platform_dependent_init_impl(rctx):
    os_name = rctx.os.name.lower()
    host_os = get_os_info(os_name)

    path_to_detect_root = rctx.path(Label("//tools/build_defs:detect_root.bzl"))
    rctx.template("detect_root.bzl", path_to_detect_root)

    rctx.file("WORKSPACE", """workspace(name='foreign_cc_platform_utils')""")
    rctx.file("BUILD.bazel", "\n".join(
        [
            _create_os_description(rctx, os_name),
            _shell_utils_text(rctx, host_os),
            _build_tools(rctx, host_os),
        ],
    ))

def _create_os_description(rctx, os_name):
    path = rctx.path(Label("//workspace:os_info.bzl"))
    rctx.template("os_info.bzl", path, executable = True)
    return "load(\":os_info.bzl\", \"define_os\")\ndefine_os(\"{}\")".format(os_name)

def _shell_utils_text(rctx, host_os):
    utils_name = "utils_unix.sh"
    if host_os.is_osx:
        utils_name = "utils_osx.sh"
    if host_os.is_win:
        utils_name = "utils_win.bat"
        fail("Not supported yet!")

    path = rctx.path(Label("//workspace:" + utils_name))
    rctx.template(utils_name, path, executable = True)

    return """
sh_library(
  name = "shell_utils",
  srcs = ["{}"],
  visibility = ["//visibility:public"]
)
""".format(utils_name)

def _build_ninja(existing, rctx, host_os):
    return existing == None

def _build_cmake(existing, rctx, host_os):
    is_ci = rctx.os.environ.get("CI")
    return existing == None and is_ci != None

_tools = {
    "cmake": struct(
        bin_path = "bin/cmake",
        file = "cmake_build.bzl",
        should_be_built = _build_cmake,
        build_script = """
load("//:cmake_build.bzl", "cmake_tool")
cmake_tool(
  name = "{name}_externally_built",
  cmake_srcs = "@cmake//:all"
)
""",
    ),
    "ninja": struct(
        bin_path = "ninja",
        file = "ninja_build.bzl",
        should_be_built = _build_ninja,
        build_script = """
load("//:ninja_build.bzl", "ninja_tool")

ninja_tool(
    name = "{name}_externally_built",
    ninja_srcs = "@ninja_build//:all",
)
""",
    ),
}

def _build_tools(rctx, host_os):
    build_text = []
    tools_text = []
    deps = []

    for tool in _tools:
        existing = rctx.which(tool)
        descriptor = _tools[tool]

        # define the rule for building the tool in any case
        definition_path = rctx.path(Label("//workspace:" + descriptor.file))
        rctx.template(descriptor.file, definition_path)
        build_text += ["""
sh_library(
 name = "{tool_name}",
 srcs = [":{tool_name}_externally_built"],
 visibility = ["//visibility:public"]
)
""".format(tool_name = tool) + descriptor.build_script.format(name = tool)]

        value = tool
        to_build_tool = descriptor.should_be_built(existing, rctx, host_os)
        if to_build_tool:
            value = "$EXT_BUILD_DEPS/bin/{}/{}".format(tool, descriptor.bin_path)
        tools_text += ["{}_USE_BUILT={}".format(tool.upper(), to_build_tool)]
        tools_text += ["{}_COMMAND=\"{}\"".format(tool.upper(), value)]

    rctx.file("tools.bzl", "\n".join(tools_text))
    return "\n".join(build_text)

_platform_dependent_init = repository_rule(
    implementation = _platform_dependent_init_impl,
)

def rules_foreign_cc_dependencies():
    repositories()
    _platform_dependent_init(name = "foreign_cc_platform_utils")
