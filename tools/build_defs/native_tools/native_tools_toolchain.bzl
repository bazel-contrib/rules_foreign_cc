# buildifier: disable=module-docstring
ToolInfo = provider(
    doc = "Information about the native tool",
    fields = {
        "path": (
            "Absolute path to the tool in case the tool is preinstalled on the machine. " +
            "Relative path to the tool in case the tool is built as part of a build; the path should be relative " +
            "to the bazel-genfiles, i.e. it should start with the name of the top directory of the built tree " +
            "artifact. (Please see the example `//examples:built_cmake_toolchain`)"
        ),
        "targets": (
            "If the tool is preinstalled, must be an empty list. " +
            "If the tool is built as part of the build, the corresponding build target, which should produce " +
            "the tree artifact with the binary to call."
        ),
    },
)

def _native_tool_toolchain(ctx):
    if not ctx.attr.path and not ctx.attr.target and not ctx.attr.targets:
        fail("Either path or targets (and path) should be defined for the tool.")
    targets = ctx.attr.targets
    if not targets and ctx.attr.target:
        targets = [ctx.attr.target]
    return platform_common.ToolchainInfo(data = ToolInfo(
        path = ctx.attr.path,
        targets = targets,
    ))

native_tool_toolchain = rule(
    doc = (
        "Rule for defining the toolchain data of the native tools (cmake, ninja), " +
        "to be used by rules_foreign_cc with toolchain types " +
        "`@rules_foreign_cc//tools/build_defs:cmake_toolchain` and " +
        "`@rules_foreign_cc//tools/build_defs:ninja_toolchain`."
    ),
    implementation = _native_tool_toolchain,
    attrs = {
        "path": attr.string(
            mandatory = False,
            doc = (
                "Absolute path to the tool in case the tool is preinstalled on the machine. " +
                "Relative path to the tool in case the tool is built as part of a build; the path should be " +
                "relative to the bazel-genfiles, i.e. it should start with the name of the top directory " +
                "of the built tree artifact. (Please see the example `//examples:built_cmake_toolchain`)"
            ),
        ),
        "targets": attr.label_list(
            mandatory = False,
            allow_empty = True,
            default = [],
            doc = (
                "If the tool is preinstalled, must be an empty list. " +
                "If the tool is built as part of the build, the corresponding build target, " +
                "which should produce the tree artifact with the binary to call."
            ),
        ),
        "target": attr.label(
            mandatory = False,
            doc = """DEPRECATED: use `targets` instead.""",
        ),
    },
)

def access_tool(toolchain_type_, ctx, tool_name):
    tool_toolchain = ctx.toolchains[toolchain_type_]
    if tool_toolchain:
        return tool_toolchain.data
    return ToolInfo(
        path = tool_name,
        targets = [],
    )
