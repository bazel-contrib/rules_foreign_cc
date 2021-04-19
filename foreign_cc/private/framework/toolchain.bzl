"""A module containing the implementation of the foreign_cc framework's toolchains"""

load("//foreign_cc/private/framework/toolchains:commands.bzl", "PLATFORM_COMMANDS")
load("//foreign_cc/private/framework/toolchains:mappings.bzl", "TOOLCHAIN_MAPPINGS")

_BUILD_FILE_CONTENT = """\
load("//:defs.bzl", "foreign_cc_framework_toolchain")

package(default_visibility = ["//visibility:public"])

exports_files(["defs.bzl"])

foreign_cc_framework_toolchain(
    name = "commands"
)

toolchain(
    name = "toolchain",
    toolchain_type = "@rules_foreign_cc//foreign_cc/private/framework:toolchain_type",
    toolchain = "//:commands",
    exec_compatible_with = {exec_compat},
    target_compatible_with = {target_compat},
)
"""

_DEFS_BZL_CONTENT = """\
load(
    "{commands_src}",
    {symbols}
)

commands = struct(
    {commands}
)

def _foreign_cc_framework_toolchain_impl(ctx):
    return platform_common.ToolchainInfo(
        commands = commands,
    )

foreign_cc_framework_toolchain = rule(
    implementation = _foreign_cc_framework_toolchain_impl,
)
"""

def _framework_toolchain_repository_impl(repository_ctx):
    # Ensure we always have an absolute label. This may not be the case
    # when building within the `@rules_foreign_cc` workspace.
    absolute_label = str(repository_ctx.attr.commands_src)
    if not absolute_label.startswith("@"):
        absolute_label = "@rules_foreign_cc" + absolute_label

    repository_ctx.file("defs.bzl", _DEFS_BZL_CONTENT.format(
        commands_src = absolute_label,
        symbols = "\n    ".join(["\"{}\",".format(symbol) for symbol in PLATFORM_COMMANDS.keys()]),
        commands = "\n    ".join(["{cmd} = {cmd},".format(cmd = symbol) for symbol in PLATFORM_COMMANDS.keys()]),
    ))

    repository_ctx.file("BUILD.bazel", _BUILD_FILE_CONTENT.format(
        exec_compat = repository_ctx.attr.exec_compatible_with,
        target_compat = repository_ctx.attr.target_compatible_with,
    ))

framework_toolchain_repository = repository_rule(
    doc = "",
    implementation = _framework_toolchain_repository_impl,
    attrs = {
        "commands_src": attr.label(
            doc = "The label of a `.bzl` source which defines toolchain commands",
            allow_files = [".bzl"],
        ),
        "exec_compatible_with": attr.string_list(
            doc = "",
        ),
        "target_compatible_with": attr.string_list(
            doc = "",
        ),
    },
)

# buildifier: disable=unnamed-macro
def register_framework_toolchains():
    """Define and register the foreign_cc framework toolchains"""
    toolchains = []

    for item in TOOLCHAIN_MAPPINGS:
        # Generate a toolchain name without the `.bzl` suffix
        toolchain_name = "rules_foreign_cc_framework_toolchain_" + item.file.name[:-len(".bzl")]

        framework_toolchain_repository(
            name = toolchain_name,
            commands_src = item.file,
            exec_compatible_with = item.exec_compatible_with,
            target_compatible_with = item.target_compatible_with,
        )

        toolchains.append("@{}//:toolchain".format(toolchain_name))

    native.register_toolchains(*toolchains)
