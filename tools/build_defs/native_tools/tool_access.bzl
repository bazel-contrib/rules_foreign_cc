"""This module has been moved to `//toolchains/native_tools:native_tools_toolchains.bzl`.
This file will be removed at some point in the future
"""

load(
    "//toolchains/native_tools:tool_access.bzl",
    _get_cmake_data = "get_cmake_data",
    _get_make_data = "get_make_data",
    _get_ninja_data = "get_ninja_data",
)

get_cmake_data = _get_cmake_data
get_make_data = _get_make_data
get_ninja_data = _get_ninja_data
