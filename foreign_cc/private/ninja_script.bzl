"""A module for creating the build script for `ninja` builds"""

load(":make_env_vars.bzl", "get_make_env_vars")
load(":make_script.bzl", "pkgconfig_script")

# buildifier: disable=function-docstring
def create_ninja_script(
        workspace_name,
        tools,
        flags,
        root,
        env_vars,
        deps,
        inputs,
        ninja_prefix,
        ninja_path,
        ninja_targets,
        ninja_args,
        ninja_directory,
        is_msvc):
    ext_build_dirs = inputs.ext_build_dirs

    script = pkgconfig_script(ext_build_dirs)

    script.append("##symlink_contents_to_dir## $$EXT_BUILD_ROOT$$/{} $$BUILD_TMPDIR$$ False".format(root))
    script.append("##enable_tracing##")

    ninja_commands = []
    for target in ninja_targets:
        ninja_commands.append("{prefix}{ninja} -C {dir} {args} {target}".format(
            prefix = ninja_prefix,
            ninja = ninja_path,
            dir = ninja_directory,
            args = ninja_args,
            target = target,
        ))

    ninja_env_vars = get_make_env_vars(
        workspace_name,
        tools,
        flags,
        env_vars,
        deps,
        inputs,
        is_msvc,
        ninja_commands,
    )

    script.extend(["{env_vars} {command}".format(
        env_vars = ninja_env_vars,
        command = command,
    ) for command in ninja_commands])
    script.append("##disable_tracing##")
    return script
