load(
    "//tools/build_defs/shell_toolchain/polymorphism:generate_overloads.bzl",
    "generate_overloads",
    "get_file_name",
)
load("//tools/build_defs/shell_toolchain/toolchains:commands.bzl", "PLATFORM_COMMANDS")
load(":toolchain_mappings.bzl", "TOOLCHAIN_MAPPINGS")

def workspace_part():
    generate_overloads(
        name = "commands_overloads",
        files = [item.file for item in TOOLCHAIN_MAPPINGS],
        symbols = PLATFORM_COMMANDS.keys(),
    )
    ordered_toolchains = []
    prefix = "@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:"
    for item in TOOLCHAIN_MAPPINGS:
        ordered_toolchains.append(prefix + get_file_name(item.file))
    native.register_toolchains(*ordered_toolchains)
