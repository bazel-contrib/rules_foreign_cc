"""Helpers for rendering foreign build flag lists."""

load(":cc_toolchain_util.bzl", "absolutize_path_in_str")

def absolutize_path_for_build_root(workspace_name, text, force = False):
    return absolutize_path_in_str(workspace_name, "$$EXT_BUILD_ROOT$$/", text, force)

def join_flags_list(workspace_name, flags):
    return " ".join([
        absolutize_path_for_build_root(workspace_name, flag)
        for flag in flags
    ])
