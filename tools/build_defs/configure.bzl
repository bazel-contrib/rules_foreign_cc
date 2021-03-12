"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

load("//foreign_cc:defs.bzl", _configure_make = "configure_make")
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

configure_make = _configure_make
