""" This module is deprecated and has been moved to `//toolchains/built_tools/...` """

load("//foreign_cc/built_tools:ninja_build.bzl", _ninja_tool = "ninja_tool")
load(":deprecation.bzl", "print_deprecation")

print_deprecation()

ninja_tool = _ninja_tool
