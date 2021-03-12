""" This module is deprecated and has been moved to `//toolchains/built_tools/...` """

load("//foreign_cc/built_tools:make_build.bzl", _make_tool = "make_tool")
load(":deprecation.bzl", "print_deprecation")

print_deprecation()

make_tool = _make_tool
