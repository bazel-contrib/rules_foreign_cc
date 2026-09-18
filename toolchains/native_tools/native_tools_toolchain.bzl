"""Rules for building native build tools such as ninja, make or cmake"""

# buildifier: disable=module-docstring
ToolInfo = provider(
    doc = "Information about the native tool",
    fields = {
        "env": "Environment variables to set when using this tool e.g. M4",
        "path": (
            "Absolute path to the tool in case the tool is preinstalled on the machine. " +
            "Relative path to the tool in case the tool is built as part of a build; the path should be relative " +
            "to the bazel-genfiles, i.e. it should start with the name of the top directory of the built tree " +
            "artifact."
        ),
        "target": (
            "If the tool is preinstalled, must be None. " +
            "If the tool is built as part of the build, the corresponding build target, which should produce " +
            "the tree artifact with the binary to call."
        ),
        "tools": (
            "Every target that has to be staged into an action using this tool, `target` included. " +
            "Empty when the tool is preinstalled and nothing is staged at all. Toolchain rules that " +
            "predate this field leave it None; read it through `tool_targets`."
        ),
    },
)

def tool_targets(tool_info):
    """Every target to stage for a tool, however old the provider is.

    `tools` was added to `ToolInfo` after the provider became public API, so a
    third-party toolchain rule that still constructs it from `path` and
    `target` alone leaves the field None. For such a tool `target` is the whole
    list, which is exactly what rfcc staged before the field existed.

    Args:
        tool_info (ToolInfo): a resolved toolchain's tool data.

    Returns:
        list of Target: the targets to stage; empty for a preinstalled tool.
    """
    if tool_info.tools != None:
        return tool_info.tools
    return [tool_info.target] if tool_info.target else []

def _resolve_tool_path(ctx, path, target, tools):
    """
        Resolve the path to a tool.

        Note that ctx.resolve_command is used instead of ctx.expand_location as the
        latter cannot be used with py_binary and sh_binary targets as they both produce multiple files in some contexts, meaning
        that the plural make variables must be used, e.g.  $(execpaths) must be used. See https://github.com/bazelbuild/bazel/issues/11820.

        The usage of ctx.resolve_command facilitates the usage of the singular make variables, e.g $(execpath), with py_binary and sh_binary targets
    """
    _, resolved_bash_command, _ = ctx.resolve_command(
        command = path,
        expand_locations = True,
        tools = tools + [target],
    )

    return resolved_bash_command[-1]

def _native_tool_toolchain_impl(ctx):
    if not ctx.attr.path and not ctx.attr.target:
        fail("Either path or target (and path) should be defined for the tool.")
    path = None
    env = {}
    if ctx.attr.target:
        path = _resolve_tool_path(ctx, ctx.attr.path, ctx.attr.target, ctx.attr.tools)

        for k, v in ctx.attr.env.items():
            env[k] = _resolve_tool_path(ctx, v, ctx.attr.target, ctx.attr.tools)

    else:
        path = ctx.expand_location(ctx.attr.path)
        env = {k: ctx.expand_location(v) for (k, v) in ctx.attr.env.items()}
    return platform_common.ToolchainInfo(data = ToolInfo(
        env = env,
        path = path,
        target = ctx.attr.target,
        tools = ([ctx.attr.target] if ctx.attr.target else []) + ctx.attr.tools,
    ))

native_tool_toolchain = rule(
    doc = (
        "Rule for defining the toolchain data of the native tools (cmake, ninja), " +
        "to be used by rules_foreign_cc with toolchain types " +
        "`@rules_foreign_cc//toolchains:cmake_toolchain` and " +
        "`@rules_foreign_cc//toolchains:ninja_toolchain`."
    ),
    implementation = _native_tool_toolchain_impl,
    attrs = {
        "env": attr.string_dict(
            doc = "Environment variables to be set when using this tool e.g. M4",
        ),
        "path": attr.string(
            mandatory = False,
            doc = (
                "Absolute path to the tool in case the tool is preinstalled on the machine. " +
                "Relative path to the tool in case the tool is built as part of a build; the path should be " +
                "relative to the bazel-genfiles, i.e. it should start with the name of the top directory " +
                "of the built tree artifact."
            ),
        ),
        "target": attr.label(
            mandatory = False,
            cfg = "exec",
            doc = (
                "If the tool is preinstalled, must be None. " +
                "If the tool is built as part of the build, the corresponding build target, " +
                "which should produce the tree artifact with the binary to call."
            ),
            allow_files = True,
        ),
        "tools": attr.label_list(
            mandatory = False,
            cfg = "exec",
            doc = (
                "Additional targets making up this tool, staged into the action alongside `target`. " +
                "Use it whenever `path` or `env` must name a single file: to isolate one file out of a " +
                "`target` that expands to several, or to add a file `target` does not produce at all, " +
                "such as the real binary behind a launcher."
            ),
            allow_files = True,
        ),
    },
)
