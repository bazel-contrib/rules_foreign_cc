"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private/shell_toolchain/toolchains:commands.bzl",
    _ArgumentInfo = "ArgumentInfo",
    _CommandInfo = "CommandInfo",
    _PLATFORM_COMMANDS = "PLATFORM_COMMANDS",
)
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

CommandInfo = _CommandInfo
ArgumentInfo = _ArgumentInfo
PLATFORM_COMMANDS = _PLATFORM_COMMANDS
