"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

load("//foreign_cc:defs.bzl", _cmake = "cmake")
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

cmake = _cmake

# This is an alias to the underlying rule and is
# kept around for legacy compaitiblity. This should
# not be removed without sufficent warning.
cmake_external = _cmake
