"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private:detect_root.bzl",
    _detect_root = "detect_root",
    _filter_containing_dirs_from_inputs = "filter_containing_dirs_from_inputs",
)
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

detect_root = _detect_root
filter_containing_dirs_from_inputs = _filter_containing_dirs_from_inputs
