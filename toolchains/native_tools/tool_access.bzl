"""A module defining convienence methoods for accessing build tools from
rules_foreign_cc toolchains
"""

# buildifier: disable=bzl-visibility
load("//foreign_cc/private/framework:exec_groups.bzl", "get_toolchains")
load(":native_tools_toolchain.bzl", "tool_targets")

def access_tool(toolchain_type_, ctx):
    """A helper macro for getting the path to a build tool's executable

    Args:
        toolchain_type_ (Label): The name of the toolchain type
        ctx (ctx): The rule's context object

    Returns:
        ToolInfo: A provider containing information about the toolchain's executable
    """
    tool_toolchain = get_toolchains(ctx)[toolchain_type_]
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
    """Like the other accessors, plus the Python side of a `meson_tool_toolchain`.

    Args:
        ctx (ctx): The rule's context object

    Returns:
        struct: the fields of the other accessors plus `python` (True for a
            `meson_tool_toolchain`) and `pythonpath`; for any other meson
            toolchain these are False and empty.
    """
    toolchain_type = Label("//toolchains:meson_toolchain")
    tool = _access_and_expect_label_copied(toolchain_type, ctx)
    meson = getattr(get_toolchains(ctx)[toolchain_type], "meson", None)

    env = dict(tool.env)
    if meson != None:
        # MESON was absolutized above like any tool; the interpreter and entry
        # script are absolutized here. REAL_MESON is an rlocationpath, left as is.
        env["PYTHON3"] = _absolutize(meson.interpreter)
        env["MESON_REAL"] = _absolutize(meson.main.path)

    return struct(
        target = tool.target,
        tools = tool.tools,
        env = env,
        path = tool.path,
        python = meson != None,
        pythonpath = [_absolutize(p) for p in meson.pythonpath] if meson != None else [],
    )

def _absolutize(path):
    """`path` as usable from $BUILD_TMPDIR: exec-root-relative paths get the root prepended."""
    if path.startswith("/") or (len(path) > 1 and path[1] == ":"):
        return path
    if path == ".":
        return "$EXT_BUILD_ROOT"
    return "$EXT_BUILD_ROOT/{}".format(path)

def get_pkgconfig_data(ctx):
    return _access_and_expect_label_copied(Label("//toolchains:pkgconfig_toolchain"), ctx)

def get_msbuild_data(ctx):
    return _access_and_expect_label_copied(Label("//toolchains:msbuild_toolchain"), ctx)

def _cmd_path(path, tools):
    """The exec-root-relative path of the staged file `path` names.

    Falls back to `path` itself when no staged target produces a match, which is
    how a `path` pointing inside a tree artifact resolves.

    Args:
        path (string): the toolchain's `path`
        tools (list of Target): the targets staged for the tool

    Returns:
        string: the path to the tool
    """
    suffix = "/" + path
    for tool_target in tools:
        for f in tool_target.files.to_list():
            if f.path.endswith(suffix):
                return f.path
    return path

def _access_and_expect_label_copied(toolchain_type_, ctx):
    tool_data = access_tool(toolchain_type_, ctx)
    if tool_data.target:
        # This could be made more efficient by changing the
        # toolchain to provide the executable as a target
        tools = tool_targets(tool_data)
        cmd_path = _cmd_path(tool_data.path, tools)
        tool_env = dict(tool_data.env)

        # Environment vars for tools such as MAKE and CMAKE needs to be absolute
        # as they are used from build_tmpdir and not bazel's exec/sandbox root
        for k, v in tool_env.items():
            if v.endswith(tool_data.path):
                tool_env[k] = "$EXT_BUILD_ROOT/{}".format(cmd_path)

        return struct(
            target = tool_data.target,
            tools = tools,
            env = tool_env,
            # as the tool will be copied into tools directory
            path = "$EXT_BUILD_ROOT/{}".format(cmd_path),
        )
    else:
        return struct(
            target = None,
            tools = [],
            env = tool_data.env,
            path = tool_data.path,
        )
