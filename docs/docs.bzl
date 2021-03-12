"""A module exporting symbols for Stardoc generation."""

load("@rules_foreign_cc//:workspace_definitions.bzl", _rules_foreign_cc_dependencies = "rules_foreign_cc_dependencies")
load(
    "@rules_foreign_cc//foreign_cc:defs.bzl",
    _boost_build = "boost_build",
    _cmake = "cmake",
    _configure_make = "configure_make",
    _make = "make",
    _ninja = "ninja",
)
load(
    "@rules_foreign_cc//foreign_cc:providers.bzl",
    _ForeignCcArtifact = "ForeignCcArtifact",
    _ForeignCcDeps = "ForeignCcDeps",
)
load("@rules_foreign_cc//foreign_cc/built_tools:cmake_build.bzl", _cmake_tool = "cmake_tool")
load("@rules_foreign_cc//foreign_cc/built_tools:make_build.bzl", _make_tool = "make_tool")
load("@rules_foreign_cc//foreign_cc/built_tools:ninja_build.bzl", _ninja_tool = "ninja_tool")
load(
    "@rules_foreign_cc//toolchains/native_tools:native_tools_toolchain.bzl",
    _ToolInfo = "ToolInfo",
    _native_tool_toolchain = "native_tool_toolchain",
)

# Rules Foreign CC symbols
boost_build = _boost_build
cmake = _cmake
cmake_tool = _cmake_tool
configure_make = _configure_make
make = _make
make_tool = _make_tool
native_tool_toolchain = _native_tool_toolchain
ninja = _ninja
ninja_tool = _ninja_tool
rules_foreign_cc_dependencies = _rules_foreign_cc_dependencies

# buildifier: disable=name-conventions
ForeignCcArtifact = _ForeignCcArtifact

# buildifier: disable=name-conventions
ForeignCcDeps = _ForeignCcDeps

# buildifier: disable=name-conventions
ToolInfo = _ToolInfo
