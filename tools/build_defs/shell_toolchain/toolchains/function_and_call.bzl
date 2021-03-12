"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private/shell_toolchain/toolchains:function_and_call.bzl",
    _FunctionAndCall = "FunctionAndCall",
)
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

# buildifier: disable=name-conventions
FunctionAndCall = _FunctionAndCall
