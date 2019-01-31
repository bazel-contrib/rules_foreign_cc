load(
    "//tools/build_defs/shell_toolchain/polymorphism:generate_overloads.bzl",
    "get_file_name",
)
load(":toolchain_mappings.bzl", "TOOLCHAIN_MAPPINGS")
load("@commands_overloads//:toolchain_data_defs.bzl", "get")

def _toolchain_data(ctx):
    return platform_common.ToolchainInfo(data = get(ctx.attr.file_name))

toolchain_data = rule(
    implementation = _toolchain_data,
    attrs = {
        "file_name": attr.string(),
    },
)

def build_part(toolchain_type_):
    register_mappings(toolchain_type_, TOOLCHAIN_MAPPINGS)

def register_mappings(toolchain_type_, mappings):
    for item in mappings:
        file_name = get_file_name(item.file)

        toolchain_data(
            name = file_name + "_data",
            file_name = file_name,
            visibility = ["//visibility:public"],
        )
        native.toolchain(
            name = file_name,
            toolchain_type = toolchain_type_,
            toolchain = file_name + "_data",
            exec_compatible_with = item.exec_compatible_with if hasattr(item, "exec_compatible_with") else [],
            target_compatible_with = item.target_compatible_with if hasattr(item, "target_compatible_with") else [],
        )
