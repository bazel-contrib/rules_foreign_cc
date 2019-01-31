load("@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:defs.bzl", "register_mappings")
load(":additional_toolchains.bzl", "ADD_TOOLCHAIN_MAPPINGS")
load(":test_platform_name_rule.bzl", "test_platform_name")

# Targets of type "toolchain" are created inside for the values of ADD_TOOLCHAIN_MAPPINGS,
# with the correct constraints taken from mappings.
# The "toolchain_data" is referencing generated @commands_overloads.
register_mappings(
    mappings = ADD_TOOLCHAIN_MAPPINGS,
    toolchain_type_ = "@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:shell_commands",
)

constraint_setting(name = "fancy_constraint")

constraint_value(
    name = "fancy_constraint_value",
    constraint_setting = ":fancy_constraint",
)

platform(
    name = "fancy_platform",
    constraint_values = [
        "@bazel_tools//platforms:linux",
        "@bazel_tools//platforms:x86_64",
        ":fancy_constraint_value",
    ],
)

test_platform_name(
    name = "test_platform_name",
    expected = "Fancy",
)
