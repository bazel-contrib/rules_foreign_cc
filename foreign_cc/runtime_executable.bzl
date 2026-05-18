"""Executable adapter for binaries produced by foreign_cc targets."""

load("@bazel_skylib//lib:shell.bzl", "shell")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("//foreign_cc/private:runtime_executable_info.bzl", "ForeignCcRuntimeExecutableInfo")

_PRIVATE_TARGET_ATTRS = [
    "compatible_with",
    "exec_compatible_with",
    "exec_group_compatible_with",
    "exec_properties",
    "restricted_to",
    "tags",
    "target_compatible_with",
    "testonly",
]

def _runtime_executable_wrapper_impl(ctx):
    if ForeignCcRuntimeExecutableInfo not in ctx.attr.foreign_cc_target:
        fail("{} does not provide foreign_cc runtime executable metadata".format(
            ctx.attr.foreign_cc_target.label,
        ))

    runtime_info = ctx.attr.foreign_cc_target[ForeignCcRuntimeExecutableInfo]
    binary = ctx.attr.binary
    if binary not in runtime_info.binaries:
        fail("runtime_executable binary '{}' was not found in {} out_binaries: {}".format(
            binary,
            ctx.attr.foreign_cc_target.label,
            ", ".join(sorted(runtime_info.binaries.keys())),
        ))

    selected_binary = runtime_info.binaries[binary]
    executable = ctx.actions.declare_file(ctx.label.name + ".sh")
    wrapper_paths = _runfile_paths(ctx, selected_binary)
    ctx.actions.expand_template(
        output = executable,
        template = ctx.file._wrapper_template,
        substitutions = {
            "%{binary_runfile_paths}": " ".join([shell.quote(path) for path in wrapper_paths]),
            "%{failure_message}": shell.quote(
                "runtime executable is not executable: " + ", ".join(wrapper_paths),
            ),
        },
        is_executable = True,
    )

    runfiles = ctx.runfiles(
        files = [selected_binary],
        transitive_files = runtime_info.runtime_files,
    )
    runfiles = runfiles.merge(ctx.attr.foreign_cc_target[DefaultInfo].default_runfiles)
    runfiles = runfiles.merge(ctx.attr._runfiles[DefaultInfo].default_runfiles)

    return [DefaultInfo(
        files = depset([executable]),
        runfiles = runfiles,
    )]

# Build the runfiles lookup keys the wrapper should try for the selected binary.
#
# File.short_path is the path fragment for declared outputs, but it is not
# always the exact key accepted by runfiles.bash rlocation. In the workspace
# that owns the adapter target, runfiles can include the workspace name as the
# first path segment, e.g. "_main/pkg/tool/bin/app", while File.short_path is
# "pkg/tool/bin/app". For external repositories, File.short_path may start
# with "../repo/", and the runfiles key drops that leading "../".
#
# Example:
#   file.short_path = "pkg/python/bin/python3.12"
#   ctx.workspace_name = "_main"
#   candidates = [
#       "_main/pkg/python/bin/python3.12",
#       "pkg/python/bin/python3.12",
#   ]
def _runfile_paths(ctx, file):
    if file.short_path.startswith("../"):
        return [file.short_path[3:]]

    if ctx.workspace_name:
        return [
            ctx.workspace_name + "/" + file.short_path,
            file.short_path,
        ]
    return [file.short_path]

_runtime_executable_wrapper = rule(
    implementation = _runtime_executable_wrapper_impl,
    attrs = {
        "binary": attr.string(
            mandatory = True,
            doc = "Exact configured entry from foreign_cc_target's out_binaries to execute.",
        ),
        "foreign_cc_target": attr.label(
            mandatory = True,
            doc = "foreign_cc target that declares the selected binary in out_binaries.",
        ),
        "_runfiles": attr.label(
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "_wrapper_template": attr.label(
            allow_single_file = True,
            default = "//foreign_cc/private:runtime_executable_wrapper.sh.tpl",
        ),
    },
)

# The public sh_binary accepts attrs like data, deps, args, and env that do
# not belong on the generated wrapper rule. Forward only attrs that affect
# test-only checks, compatibility, or wrapper action execution behavior.
def _private_target_kwargs(kwargs):
    return {
        key: kwargs[key]
        for key in _PRIVATE_TARGET_ATTRS
        if key in kwargs
    }

def runtime_executable(name, binary, foreign_cc_target, **kwargs):
    """Turns a selected foreign_cc binary output into an executable Bazel target.

    This adapter is separate from the producing foreign_cc rule because
    foreign_cc outputs are not always expected to contain binaries, so the
    producing rule cannot always expose an executable.

    The selected binary must be declared by the producing target's out_binaries
    attribute. If that binary depends directly or transitively on
    foreign_cc-produced shared libraries, the producing foreign_cc target may
    also need runtime_library_search_directories = "enabled".

    runtime_executable is a more Bazel-native form of runnable_binary because it
    exposes the executable through DefaultInfo.files_to_run for downstream
    consumers. Its API is intentionally similar to runnable_binary, but it does
    not completely replace runnable_binary while
    runtime_library_search_directories defaults to "disabled".

    The adapter creates a runfiles-aware shell wrapper that resolves the
    selected binary through Bazel runfiles, exports runfiles environment
    variables, and reports a clear error if the binary cannot be located or
    executed.

    Args:
      name: Name of the executable target.
      binary: Exact configured entry from foreign_cc_target's out_binaries to execute.
      foreign_cc_target: foreign_cc target that declares the selected binary in
        out_binaries.
      **kwargs: Common rule attributes forwarded to the public sh_binary target.
        Compatibility-related attributes are also applied to the generated
        wrapper target.
    """
    wrapper_name = name + "_wrapper"
    wrapper_kwargs = _private_target_kwargs(kwargs)
    wrapper_kwargs["tags"] = wrapper_kwargs.get("tags", []) + ["manual"]

    _runtime_executable_wrapper(
        name = wrapper_name,
        binary = binary,
        foreign_cc_target = foreign_cc_target,
        **wrapper_kwargs
    )

    sh_binary(
        name = name,
        srcs = [":" + wrapper_name],
        data = [":" + wrapper_name],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        **kwargs
    )
