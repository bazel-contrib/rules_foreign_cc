"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private:cmake_script.bzl",
    _create_cmake_script = "create_cmake_script",
)
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

create_cmake_script = _create_cmake_script
