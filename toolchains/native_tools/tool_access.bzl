"""A module defining convienence methoods for accessing build tools from
rules_foreign_cc toolchains
"""

def access_tool(toolchain_type_, ctx):
    """A helper macro for getting the path to a build tool's executable

    Args:
        toolchain_type_ (Label): The name of the toolchain type
        ctx (ctx): The rule's context object

    Returns:
        ToolInfo: A provider containing information about the toolchain's executable
    """
    tool_toolchain = ctx.toolchains[toolchain_type_]
    if tool_toolchain:
        return tool_toolchain.data
    fail("No toolchain found for " + toolchain_type_)

def get_autoconf_data(ctx):
    return _access_and_expect_label_copied(Label("//toolchains:autoconf_toolchain"), ctx)

def get_automake_data(ctx):
    return _access_and_expect_label_copied(Label("//toolchains:automake_toolchain"), ctx)

def get_cmake_data(ctx):
    return _access_and_expect_label_copied(Label("//toolchains:cmake_toolchain"), ctx)

def get_m4_data(ctx):
    return _access_and_expect_label_copied(Label("//toolchains:m4_toolchain"), ctx)

def get_make_data(ctx):
    return _access_and_expect_label_copied(Label("//toolchains:make_toolchain"), ctx)

def get_ninja_data(ctx):
    return _access_and_expect_label_copied(Label("//toolchains:ninja_toolchain"), ctx)

def get_meson_data(ctx):
    return _access_and_expect_label_copied(Label("//toolchains:meson_toolchain"), ctx)

def get_pkgconfig_data(ctx):
    return _access_and_expect_label_copied(Label("//toolchains:pkgconfig_toolchain"), ctx)

def _access_and_expect_label_copied(toolchain_type_, ctx):
    tool_data = access_tool(toolchain_type_, ctx)
    if tool_data.target:
        tool_env = dict(tool_data.env)
        resolved_tool_path = "$$EXT_BUILD_ROOT$$/{}".format(tool_data.invoke_path)
        if tool_data.staged_path:
            resolved_tool_path = "$$EXT_BUILD_DEPS$$/{}".format(tool_data.staged_path)

        for k, v in tool_env.items():
            if v.endswith(tool_data.invoke_path):
                tool_env[k] = resolved_tool_path

        return struct(
            target = tool_data.target,
            env = tool_env,
            bin_entry_path = "$$EXT_BUILD_ROOT$$/{}".format(tool_data.invoke_path),
            launcher_runfiles_dir = tool_data.launcher_runfiles_dir,
            launcher_support_files = tool_data.launcher_support_files,
            path = resolved_tool_path,
            runfiles_manifest = tool_data.runfiles_manifest,
            repo_mapping_manifest = tool_data.repo_mapping_manifest,
            staged_path = tool_data.staged_path,
        )
    else:
        return struct(
            target = None,
            env = tool_data.env,
            bin_entry_path = None,
            launcher_runfiles_dir = None,
            launcher_support_files = [],
            path = tool_data.path,
            runfiles_manifest = None,
            repo_mapping_manifest = None,
            staged_path = None,
        )
