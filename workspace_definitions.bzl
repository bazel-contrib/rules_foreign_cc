"""Deprecated in favor of `//foreign_cc:repositories.bzl"""

load("//foreign_cc:repositories.bzl", _rules_foreign_cc_dependencies = "rules_foreign_cc_dependencies")

# buildifier: disable=print
print(
    "`@rules_foreign_cc//:workspace_definitions.bzl` has been replaced by " +
    "`@rules_foreign_cc//foreign_cc:repositories.bzl`. Please use the " +
    "updated source location",
)

rules_foreign_cc_dependencies = _rules_foreign_cc_dependencies
