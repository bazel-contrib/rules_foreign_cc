"""Helpers for rendering foreign build flag lists."""

load(":cc_toolchain_util.bzl", "absolutize_path_in_str")

def absolutize_path_for_build_root(workspace_name, text, force = False):
    return absolutize_path_in_str(workspace_name, "$$EXT_BUILD_ROOT$$/", text, force)

def escape_dquote_bash(text):
    """Escape double quotes in a flag so they reach the foreign build's compiler.

    A quote in a toolchain flag is part of the flag's value, not shell grouping.
    Two layers strip one level each: bash setting the variable in the generated
    script, and the foreign build re-parsing the variable into a command line.
    """

    # We use a starlark raw string to prevent the need to escape backslashes for starlark as well.
    return text.replace('"', r'\\\"')

def join_flags_list(workspace_name, flags):
    return " ".join([
        absolutize_path_for_build_root(workspace_name, flag)
        for flag in flags
    ])
