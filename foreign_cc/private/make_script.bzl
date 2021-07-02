"""A module for creating the build script for `make` builds"""

def create_make_script(
        root,
        inputs,
        make_commands):
    """Constructs Make script to be passed to cc_external_rule_impl.

    Args:
        root (str): sources root relative to the $EXT_BUILD_ROOT
        inputs (struct): An InputFiles provider
        make_commands (list): Lines of bash which invoke make

    Returns:
        list: Lines of bash which make up the build script
    """
    ext_build_dirs = inputs.ext_build_dirs

    script = pkgconfig_script(ext_build_dirs)

    script.append("##symlink_contents_to_dir## $$EXT_BUILD_ROOT$$/{} $$BUILD_TMPDIR$$".format(root))

    script.append("##enable_tracing##")
    script.extend(make_commands)
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
