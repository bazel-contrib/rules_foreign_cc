ToolInfo = provider(
    doc = "Information about the native tool",
    fields = {
        "path": """Absolute path to the tool in case the tool is preinstalled on the machine.
Relative path to the tool in case the tool is built as part of a build; the path should be relative
to the bazel-genfiles, i.e. it should start with the name of the top directory of the built tree
artifact. (Please see the example "//examples:built_cmake_toolchain")""",
        "label": """If the tool is preinstalled, must be None.
If the tool is built as part of the build, the corresponding build target, which should produce
the tree artifact with the binary to call.""",
    },
)

def _native_tool_toolchain(ctx):
    if not ctx.attr.path and not ctx.attr.label:
        fail("Either path or label (and path) should be defined for the tool.")
    return platform_common.ToolchainInfo(data = ToolInfo(
        path = ctx.attr.path,
        label = ctx.attr.label,
    ))

native_tool_toolchain = rule(
    implementation = _native_tool_toolchain,
    attrs = {
        "path": attr.string(mandatory = False),
        "label": attr.label(mandatory = False),
    },
)

def access_tool(toolchain_type_, ctx, tool_name):
    tool_toolchain = ctx.toolchains[toolchain_type_]
    if tool_toolchain:
        return tool_toolchain.data
    return ToolInfo(
        path = tool_name,
        label = None,
    )
