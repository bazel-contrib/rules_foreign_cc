""" Rule for building Ninja from sources. """

load(
    "//foreign_cc/built_tools/private:built_tools_framework.bzl",
    "FOREIGN_CC_BUILT_TOOLS_ATTRS",
    "FOREIGN_CC_BUILT_TOOLS_FRAGMENTS",
    "FOREIGN_CC_BUILT_TOOLS_HOST_FRAGMENTS",
    "absolutize",
    "built_tool_rule_impl",
    "split_system_include_flags",
)
load("//foreign_cc/private:cc_toolchain_util.bzl", "get_flags_info", "get_tools_info")
load("//foreign_cc/private/framework:helpers.bzl", "escape_dquote_bash")
load("//foreign_cc/private/framework:platform.bzl", "os_name")

def _ninja_tool_impl(ctx):
    py_toolchain = ctx.toolchains["@rules_python//python:toolchain_type"]

    additional_tools = depset(
        [py_toolchain.py3_runtime.interpreter],
        transitive = [py_toolchain.py3_runtime.files],
    )

    absolute_py_interpreter_path = absolutize(ctx.workspace_name, py_toolchain.py3_runtime.interpreter.path, True)

    # ninja's configure.py honors CXX / CXXFLAGS / LDFLAGS from the env
    # during --bootstrap; forward the Bazel toolchain compiler and flags so
    # toolchain copts/linkopts reach the bootstrap compile rather than
    # whatever `c++` happens to be on PATH.
    flags = get_flags_info(ctx)
    tools = get_tools_info(ctx)

    cxxflags = flags.cxx
    ldflags = flags.cxx_linker_executable

    # configure.py invokes $CXX once with both compile- and link-style
    # arguments; --sysroot / -isystem must reach both that invocation and
    # any sub-link. Append them directly to CXX so they're always present.
    system_cxx, plain_cxx = split_system_include_flags(cxxflags)
    system_ld, plain_ld = split_system_include_flags(ldflags)

    absolute_cxx = absolutize(ctx.workspace_name, tools.cxx, True)
    if system_cxx:
        absolute_cxx += " " + _join_flags_list(ctx.workspace_name, system_cxx)
    if system_ld:
        absolute_cxx += " " + _join_flags_list(ctx.workspace_name, system_ld)

    bootstrap_env = ["CXX=\"{}\"".format(absolute_cxx)]
    if plain_cxx:
        bootstrap_env.append("CXXFLAGS=\"{}\"".format(_join_flags_list(ctx.workspace_name, plain_cxx)))
    if plain_ld:
        bootstrap_env.append("LDFLAGS=\"{}\"".format(_join_flags_list(ctx.workspace_name, plain_ld)))

    script = [
        "{} \"{}\" ./configure.py --bootstrap".format(
            " ".join(bootstrap_env),
            absolute_py_interpreter_path,
        ),
        "mkdir \"$$INSTALLDIR$$/bin\"",
        "cp -p ./ninja{} \"$$INSTALLDIR$$/bin/\"".format(
            ".exe" if "win" in os_name(ctx) else "",
        ),
    ]

    return built_tool_rule_impl(
        ctx,
        script,
        ctx.actions.declare_directory("ninja"),
        "BootstrapNinjaBuild",
        additional_tools,
    )

def _join_flags_list(workspace_name, flags):
    return " ".join([escape_dquote_bash(absolutize(workspace_name, flag)) for flag in flags])

ninja_tool = rule(
    doc = "Rule for building Ninja. Invokes configure script.",
    attrs = FOREIGN_CC_BUILT_TOOLS_ATTRS,
    host_fragments = FOREIGN_CC_BUILT_TOOLS_HOST_FRAGMENTS,
    fragments = FOREIGN_CC_BUILT_TOOLS_FRAGMENTS,
    output_to_genfiles = True,
    implementation = _ninja_tool_impl,
    toolchains = [
        "@rules_foreign_cc//foreign_cc/private/framework:shell_toolchain",
        "@bazel_tools//tools/cpp:toolchain_type",
        "@rules_python//python:toolchain_type",
    ],
)
