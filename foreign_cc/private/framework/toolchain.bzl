"""A module containing the implementation of the foreign_cc framework's toolchains"""

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
    toolchain_type = "@rules_foreign_cc//foreign_cc/private/framework:shell_toolchain",
    toolchain = ":commands",
    exec_compatible_with = {exec_compat},
    target_compatible_with = {target_compat},
)
"""

_DEFS_BZL_CONTENT = """\
load(
    "{commands_src}",
    "commands"
)

def _foreign_cc_framework_toolchain_impl(ctx):
    return platform_common.ToolchainInfo(
        commands = commands,
    )

foreign_cc_framework_toolchain = rule(
    doc = "A toolchain contianing foreign_cc commands",
    implementation = _foreign_cc_framework_toolchain_impl,
)
"""

def _framework_toolchain_repository_impl(repository_ctx):
    """The implementation of `framework_toolchain_repository`

    Args:
        repository_ctx (repository_ctx): The rule's context object
    """

    repository_ctx.file("defs.bzl", _DEFS_BZL_CONTENT.format(
        commands_src = repository_ctx.attr.commands_src,
    ))

    repository_ctx.file("BUILD.bazel", _BUILD_FILE_CONTENT.format(
        exec_compat = repository_ctx.attr.exec_compatible_with,
        target_compat = repository_ctx.attr.target_compatible_with,
    ))

framework_toolchain_repository = repository_rule(
    doc = "A repository rule which defines a `@rules_foreign_cc//foreign_cc/private/framework:shell_toolchain` toolchain.",
    implementation = _framework_toolchain_repository_impl,
    attrs = {
        "commands_src": attr.string(
            doc = "The string of a `.bzl` source which defines toolchain commands",
        ),
        "exec_compatible_with": attr.string_list(
            doc = "A list of constraint_values that must be present in the execution platform for this target.",
        ),
        "target_compatible_with": attr.string_list(
            doc = "A list of constraint_values that must be present in the target platform for this target to be considered compatible.",
        ),
    },
)

# buildifier: disable=unnamed-macro
def register_framework_toolchains(register_toolchains = True):
    """Define and register the foreign_cc framework toolchains

    Args:
        register_toolchains: Whether to call native.register_toolchains or not
    """
    toolchains = []

    for item in TOOLCHAIN_MAPPINGS:
        framework_toolchain_repository(
            name = item.repo_name,
            commands_src = item.file,
            exec_compatible_with = item.exec_compatible_with,
            target_compatible_with = item.target_compatible_with,
        )

        toolchains.append("@{}//:toolchain".format(item.repo_name))

    if register_toolchains:
        native.register_toolchains(*toolchains)
