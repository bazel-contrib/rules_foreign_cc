"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

load("//foreign_cc:defs.bzl", _ninja = "ninja")
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

ninja = _ninja
