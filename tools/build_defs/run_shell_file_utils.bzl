"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private:run_shell_file_utils.bzl",
    _CreatedByScript = "CreatedByScript",
    _copy_directory = "copy_directory",
    _fictive_file_in_genroot = "fictive_file_in_genroot",
)
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

# buildifier: disable=name-conventions
CreatedByScript = _CreatedByScript
fictive_file_in_genroot = _fictive_file_in_genroot
copy_directory = _copy_directory
