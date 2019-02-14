load(":native_tools_toolchain.bzl", "ToolInfo", "access_tool")

def get_cmake_data(ctx):
    return _access_and_expect_label_copied("@rules_foreign_cc//tools/build_defs:cmake_toolchain", ctx, "cmake")

def get_ninja_data(ctx):
    return _access_and_expect_label_copied("@rules_foreign_cc//tools/build_defs:ninja_toolchain", ctx, "ninja")

def _access_and_expect_label_copied(toolchain_type_, ctx, tool_name):
    tool_data = access_tool(toolchain_type_, ctx, tool_name)
    if tool_data.target:
        return struct(
            deps = [tool_data.target],
            # as the tool will be copied into tools directory
            path = "$EXT_BUILD_DEPS/bin/{}".format(tool_data.path),
        )
    else:
        return struct(
            deps = [],
            path = tool_data.path,
        )
