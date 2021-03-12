"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private/shell_toolchain/polymorphism:generate_overloads.bzl",
    _generate_overloads = "generate_overloads",
)
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

generate_overloads = _generate_overloads
