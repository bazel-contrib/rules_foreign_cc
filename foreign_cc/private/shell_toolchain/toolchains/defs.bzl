# buildifier: disable=module-docstring
load("@rules_foreign_cc_commands_overloads//:toolchain_data_defs.bzl", "get")
load(
    "//foreign_cc/private/shell_toolchain/polymorphism:generate_overloads.bzl",
    "get_file_name",
)
load(":toolchain_mappings.bzl", "TOOLCHAIN_MAPPINGS")

def _toolchain_data(ctx):
    return platform_common.ToolchainInfo(data = get(ctx.attr.file_name))

toolchain_data = rule(
    implementation = _toolchain_data,
    attrs = {
        "file_name": attr.string(),
    },
)

# buildifier: disable=unnamed-macro
def build_part(toolchain_type):
    register_mappings(toolchain_type, TOOLCHAIN_MAPPINGS)

# buildifier: disable=unnamed-macro
def register_mappings(toolchain_type, mappings):
    for item in mappings:
        file_name = get_file_name(item.file)

        toolchain_data(
            name = file_name + "_data",
            file_name = file_name,
            visibility = ["//visibility:public"],
        )
        native.toolchain(
            name = file_name,
            toolchain_type = toolchain_type,
            toolchain = file_name + "_data",
            exec_compatible_with = item.exec_compatible_with if hasattr(item, "exec_compatible_with") else [],
            target_compatible_with = item.target_compatible_with if hasattr(item, "target_compatible_with") else [],
        )
