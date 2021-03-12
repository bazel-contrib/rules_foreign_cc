"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private/shell_toolchain/toolchains:access.bzl",
    _call_shell = "call_shell",
    _check_argument_types = "check_argument_types",
    _create_context = "create_context",
)
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

create_context = _create_context
call_shell = _call_shell
check_argument_types = _check_argument_types
