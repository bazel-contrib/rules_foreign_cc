"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private/shell_toolchain/toolchains:toolchain_mappings.bzl",
    _TOOLCHAIN_MAPPINGS = "TOOLCHAIN_MAPPINGS",
    _ToolchainMapping = "ToolchainMapping",
)
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

# buildifier: disable=name-conventions
ToolchainMapping = _ToolchainMapping
TOOLCHAIN_MAPPINGS = _TOOLCHAIN_MAPPINGS
