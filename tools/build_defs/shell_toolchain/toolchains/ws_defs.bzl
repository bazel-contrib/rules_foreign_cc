"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private/shell_toolchain/toolchains:ws_defs.bzl",
    _workspace_part = "workspace_part",
)
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

workspace_part = _workspace_part
