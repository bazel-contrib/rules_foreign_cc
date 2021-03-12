"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

load("//foreign_cc:defs.bzl", _make = "make")
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

make = _make
