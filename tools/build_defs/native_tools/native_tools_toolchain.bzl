"""This module has been moved to `//toolchains/native_tools:native_tools_toolchains.bzl`.
This file will be removed at some point in the future
"""

load("//toolchains/native_tools:native_tools_toolchain.bzl", _native_tool_toolchain = "native_tool_toolchain")
load("//toolchains/native_tools:tool_access.bzl", _access_tool = "access_tool")

native_tool_toolchain = _native_tool_toolchain
access_tool = _access_tool
