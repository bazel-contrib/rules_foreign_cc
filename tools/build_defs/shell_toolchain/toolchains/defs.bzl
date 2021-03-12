"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private/shell_toolchain/toolchains:defs.bzl",
    _build_part = "build_part",
    _register_mappings = "register_mappings",
    _toolchain_data = "toolchain_data",
)
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

build_part = _build_part
register_mappings = _register_mappings
toolchain_data = _toolchain_data
