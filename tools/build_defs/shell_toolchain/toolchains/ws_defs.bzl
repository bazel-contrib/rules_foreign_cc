load(
    "//tools/build_defs/shell_toolchain/polymorphism:generate_overloads.bzl",
    "generate_overloads",
    "get_file_name",
)
load("//tools/build_defs/shell_toolchain/toolchains:commands.bzl", "PLATFORM_COMMANDS")
load(":toolchain_mappings.bzl", "TOOLCHAIN_MAPPINGS")

def workspace_part(
        additional_toolchain_mappings = [],
        additonal_shell_toolchain_package = None):
    mappings = additional_toolchain_mappings + TOOLCHAIN_MAPPINGS
    generate_overloads(
        name = "commands_overloads",
        files = [item.file for item in mappings],
        symbols = PLATFORM_COMMANDS.keys(),
    )
    ordered_toolchains = []
    for item in additional_toolchain_mappings:
        if not additonal_shell_toolchain_package:
            fail("Please specify the package, where the toolchains will be created")
        if not additonal_shell_toolchain_package.endswith(":"):
            additonal_shell_toolchain_package = additonal_shell_toolchain_package + ":"
        ordered_toolchains.append(additonal_shell_toolchain_package + get_file_name(item.file))
    prefix = "@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:"
    for item in TOOLCHAIN_MAPPINGS:
        ordered_toolchains.append(prefix + get_file_name(item.file))
    native.register_toolchains(*ordered_toolchains)
