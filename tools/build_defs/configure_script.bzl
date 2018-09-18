load(":cc_toolchain_util.bzl", "absolutize_path_in_str")

def create_configure_script(
        workspace_name,
        target_os,
        tools,
        flags,
        root,
        user_options,
        user_vars,
        is_debug,
        configure_command,
        inputs):
    vars = _get_configure_variables(tools, flags, user_vars)
    deps_flags = _define_deps_flags(inputs)

    vars["LDFLAGS"] = vars["LDFLAGS"] + deps_flags["LDFLAGS"]
    vars["CPPFLAGS"] = deps_flags["CPPFLAGS"]

    env_vars_string = " ".join(["{}=\"{}\"".format(key, _join_flags_list(workspace_name, vars[key])) for key in vars])

    script = []
    for ext_dir in inputs.ext_build_dirs:
        script += ["increment_pkg_config_path $EXT_BUILD_ROOT/" + ext_dir.path]

    script += ["echo \"PKG_CONFIG_PATH=$PKG_CONFIG_PATH\""]

    script += ["{env_vars} \"$EXT_BUILD_ROOT/{root}/{configure}\" --prefix=$BUILD_TMPDIR/$INSTALL_PREFIX {user_options}".format(
        env_vars = env_vars_string,
        root = root,
        configure = configure_command,
        user_options = " ".join(user_options),
    )]
    return "\n".join(script)

def _define_deps_flags(inputs):
    libs = inputs.libs

    # It is very important to keep the order for the linker => put them into list
    lib_dirs = []

    # For filtering duplicates
    lib_dirs_set = {}
    for lib in libs:
        dir = lib.dirname
        if not lib_dirs_set.get(dir):
            lib_dirs_set[dir] = 1
            lib_dirs += [dir]

    include_dirs = {}
    for include_dir in inputs.deps_compilation_info.system_includes:
        include_dirs[include_dir] = 1

    return {
        "LDFLAGS": ["-L" + dir for dir in lib_dirs],
        "CPPFLAGS": ["-I" + dir for dir in include_dirs],
    }

# See https://www.gnu.org/software/make/manual/html_node/Implicit-Variables.html
_CONFIGURE_FLAGS = {
    "CFLAGS": "cc",
    "CXXFLAGS": "cxx",
    "ARFLAGS": "cxx_linker_static",
    "ASFLAGS": "assemble",
    "LDFLAGS": "cxx_linker_executable",
    # missing: cxx_linker_shared
}

_CONFIGURE_TOOLS = {
    "CC": "cc",
    "CXX": "cxx",
    "AR": "cxx_linker_static",
    # missing: cxx_linker_executable
}

def _get_configure_variables(tools, flags, user_env_vars):
    dict = {}

    for flag in _CONFIGURE_FLAGS:
        flag_value = getattr(flags, _CONFIGURE_FLAGS[flag])
        if flag_value:
            dict[flag] = flag_value

    # Merge flags lists
    for user_var in user_env_vars:
        toolchain_val = dict.get(user_var)
        if toolchain_val:
            dict[user_var] = toolchain_val + [user_env_vars[user_var]]

    tools_dict = {}
    for tool in _CONFIGURE_TOOLS:
        tool_value = getattr(tools, _CONFIGURE_TOOLS[tool])
        if tool_value:
            tools_dict[tool] = [tool_value]

    # Replace tools paths if user passed other values
    for user_var in user_env_vars:
        toolchain_val = tools_dict.get(user_var)
        if toolchain_val:
            tools_dict[user_var] = [user_env_vars[user_var]]

    dict.update(tools_dict)

    # Put all other environment variables, passed by the user
    for user_var in user_env_vars:
        if not dict.get(user_var):
            dict[user_var] = [user_env_vars[user_var]]

    return dict

def _absolutize(workspace_name, text):
    return absolutize_path_in_str(workspace_name, "$EXT_BUILD_ROOT/", text)

def _join_flags_list(workspace_name, flags):
    return " ".join([_absolutize(workspace_name, flag) for flag in flags])
