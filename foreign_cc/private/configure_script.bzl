# buildifier: disable=module-docstring
load(":make_script.bzl", "get_env_vars", "pkgconfig_script")

# buildifier: disable=function-docstring
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
        deps,
        inputs,
        configure_in_place,
        autoconf,
        autoconf_options,
        autoconf_env_vars,
        autoreconf,
        autoreconf_options,
        autoreconf_env_vars,
        autogen,
        autogen_command,
        autogen_options,
        autogen_env_vars,
        make_commands):
    env_vars_string = get_env_vars(workspace_name, tools, flags, user_vars, deps, inputs)

    ext_build_dirs = inputs.ext_build_dirs

    script = pkgconfig_script(ext_build_dirs)

    root_path = "$$EXT_BUILD_ROOT$$/{}".format(root)
    configure_path = "{}/{}".format(root_path, configure_command)
    if configure_in_place:
        script.append("##symlink_contents_to_dir## $$EXT_BUILD_ROOT$$/{} $$BUILD_TMPDIR$$".format(root))
        root_path = "$$BUILD_TMPDIR$$"
        configure_path = "{}/{}".format(root_path, configure_command)

    if autogen and configure_in_place:
        # NOCONFIGURE is pseudo standard and tells the script to not invoke configure.
        # We explicitly invoke configure later.
        autogen_env_vars = _get_autogen_env_vars(autogen_env_vars)
        script.append('{} "{}/{}" {}'.format(
            " ".join(['{}="{}"'.format(key, autogen_env_vars[key]) for key in autogen_env_vars]),
            root_path,
            autogen_command,
            " ".join(autogen_options),
        ).lstrip())

    if autoconf and configure_in_place:
        script.append("{} autoconf {}".format(
            " ".join(["{}=\"{}\"".format(key, autoconf_env_vars[key]) for key in autoconf_env_vars]),
            " ".join(autoconf_options),
        ).lstrip())

    if autoreconf and configure_in_place:
        script.append("{} autoreconf {}".format(
            " ".join(['{}="{}"'.format(key, autoreconf_env_vars[key]) for key in autoreconf_env_vars]),
            " ".join(autoreconf_options),
        ).lstrip())

    script.append('{env_vars} "{configure}" --prefix=$$BUILD_TMPDIR$$/$$INSTALL_PREFIX$$ {user_options}'.format(
        env_vars = env_vars_string,
        configure = configure_path,
        user_options = " ".join(user_options),
    ))

    script.append("set -x")
    script.extend(make_commands)
    script.append("set +x")

    return script

def _get_autogen_env_vars(autogen_env_vars):
    # Make a copy if necessary so we can set NOCONFIGURE.
    if autogen_env_vars.get("NOCONFIGURE"):
        return autogen_env_vars
    vars = {}
    for key in autogen_env_vars:
        vars[key] = autogen_env_vars.get(key)
    vars["NOCONFIGURE"] = "1"
    return vars
