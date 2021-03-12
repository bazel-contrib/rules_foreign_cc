""" This module is deprecated and has been moved to `//toolchains/built_tools/...` """

load("//foreign_cc/built_tools:cmake_build.bzl", _cmake_tool = "cmake_tool")
load(":deprecation.bzl", "print_deprecation")

print_deprecation()

cmake_tool = _cmake_tool
