# buildifier: disable=module-docstring
# buildifier: disable=function-docstring
def create_make_script(
        root,
        inputs,
        make_commands):
    ext_build_dirs = inputs.ext_build_dirs

    script = pkgconfig_script(ext_build_dirs)

    script.append("##symlink_contents_to_dir## $$EXT_BUILD_ROOT$$/{} $$BUILD_TMPDIR$$".format(root))

    script.append("##enable_tracing##")
    script.extend(make_commands)
    script.append("##disable_tracing##")
    return script

# buildifier: disable=function-docstring-args
# buildifier: disable=function-docstring-return
def pkgconfig_script(ext_build_dirs):
    """Create a script fragment to configure pkg-config"""
    script = []
    if ext_build_dirs:
        for ext_dir in ext_build_dirs:
            script.append("##increment_pkg_config_path## $$EXT_BUILD_DEPS$$/" + ext_dir.basename)
        script.append("echo \"PKG_CONFIG_PATH=$${PKG_CONFIG_PATH:-}$$\"")

    script.append("##define_absolute_paths## $$EXT_BUILD_DEPS$$ $$EXT_BUILD_DEPS$$")

    return script
