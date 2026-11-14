"""A module for creating the build script for `ninja` builds"""

load("@bazel_skylib//lib:shell.bzl", "shell")
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
        is_msvc,
        runtime_paths,
        runtime_dirs,
        runtime_dir_separator):
    ext_build_dirs = inputs.ext_build_dirs

    script = pkgconfig_script(ext_build_dirs)

    script.append("##symlink_contents_to_dir## $$EXT_BUILD_ROOT$$/{} $$BUILD_TMPDIR$$ False".format(root))
    script.append("##enable_tracing##")
    script.extend(_runtime_setup(runtime_paths, runtime_dirs, runtime_dir_separator))

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

def _runtime_setup(paths, directories, directory_separator):
    if not paths:
        return []

    # Ninja reads link commands from the manifest. The project places this
    # response file after its objects and libraries, where archive order matters.
    script = [
        'export RFCC_CC_RUNTIME_RESPONSE_FILE="$$EXT_BUILD_DEPS$$/cc_runtime.rsp"',
        "for _rfcc_runtime_path in {}; do".format(" ".join([_absolute_runtime_path(path) for path in paths])),
        # Quote each operand for the compiler driver's response file parser.
        r"  _rfcc_runtime_path=${_rfcc_runtime_path//\\/\\\\}",
        r'  _rfcc_runtime_path=${_rfcc_runtime_path//\"/\\\"}',
        r'''  printf '"%s"\n' "$_rfcc_runtime_path"''',
        'done > "$RFCC_CC_RUNTIME_RESPONSE_FILE"',
    ]

    if directories:
        # Let the project set its loader path only when it runs a target binary.
        separator = '"{}"'.format(directory_separator)
        script.append("export RFCC_CC_RUNTIME_LIBRARY_DIRS=" + separator.join([
            _absolute_runtime_path(directory)
            for directory in directories
        ]))
    return script

def _absolute_runtime_path(path):
    # Split literal dollars from the path so the framework only expands its own $$ markers.
    return '"$$EXT_BUILD_ROOT$$/"' + "\\$".join([shell.quote(part) for part in path.split("$")])

export_for_test = struct(runtime_setup = _runtime_setup)
