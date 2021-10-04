"""A module for creating the build script for `make` builds"""

load(":make_env_vars.bzl", "get_make_env_vars")

# buildifier: disable=function-docstring
def create_make_script(
        workspace_name,
        tools,
        flags,
        root,
        env_vars,
        deps,
        inputs,
        make_commands):
    ext_build_dirs = inputs.ext_build_dirs

    script = pkgconfig_script(ext_build_dirs)

    script.append("##symlink_contents_to_dir## $$EXT_BUILD_ROOT$$/{} $$BUILD_TMPDIR$$".format(root))

    script.append("##enable_tracing##")
    configure_vars = get_make_env_vars(workspace_name, tools, flags, env_vars, deps, inputs)
    script.extend(["{env_vars} {command}".format(
        env_vars = configure_vars,
        command = command,
    ) for command in make_commands])
    script.append("##disable_tracing##")
    return script

def pkgconfig_script(ext_build_dirs):
    """Create a script fragment to configure pkg-config

    Args:
        ext_build_dirs (list): A list of directories (str)

    Returns:
        list: Lines of bash that perform the update of `pkg-config`
    """
    script = []
    if ext_build_dirs:
        for ext_dir in ext_build_dirs:
            script.append("##increment_pkg_config_path## $$EXT_BUILD_DEPS$$/" + ext_dir.basename)
        script.append("echo \"PKG_CONFIG_PATH=$${PKG_CONFIG_PATH:-}$$\"")

    script.extend([
        "##define_absolute_paths## $$EXT_BUILD_DEPS$$ $$EXT_BUILD_DEPS$$",
        "##define_sandbox_paths## $$EXT_BUILD_DEPS$$ $$EXT_BUILD_ROOT$$",
    ])

    return script
