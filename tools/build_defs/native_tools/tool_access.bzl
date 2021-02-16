# buildifier: disable=module-docstring
load(":native_tools_toolchain.bzl", "access_tool")

def get_cmake_data(ctx):
    return _access_and_expect_label_copied("@rules_foreign_cc//tools/build_defs:cmake_toolchain", ctx, "cmake")

def get_ninja_data(ctx):
    return _access_and_expect_label_copied("@rules_foreign_cc//tools/build_defs:ninja_toolchain", ctx, "ninja")

def get_make_data(ctx):
    return _access_and_expect_label_copied("@rules_foreign_cc//tools/build_defs:make_toolchain", ctx, "make")

def _access_and_expect_label_copied(toolchain_type_, ctx, tool_name):
    tool_data = access_tool(toolchain_type_, ctx, tool_name)
    if tool_data.target:
        # This could be made more efficient by changing the
        # toolchain to provide the executable as a target
        cmd_file = tool_data
        for f in tool_data.target.files.to_list():
            if f.path.endswith("/" + tool_data.path):
                cmd_file = f
                break
        return struct(
            deps = [tool_data.target],
            # as the tool will be copied into tools directory
            path = "$EXT_BUILD_ROOT/{}".format(cmd_file.path),
        )
    else:
        return struct(
            deps = [],
            path = tool_data.path,
        )
