"""A module exporting symbols for Stardoc generation."""

load("@rules_foreign_cc//:workspace_definitions.bzl", _rules_foreign_cc_dependencies = "rules_foreign_cc_dependencies")
load("@rules_foreign_cc//foreign_cc/built_tools:cmake_build.bzl", _cmake_tool = "cmake_tool")
load("@rules_foreign_cc//foreign_cc/built_tools:make_build.bzl", _make_tool = "make_tool")
load("@rules_foreign_cc//foreign_cc/built_tools:ninja_build.bzl", _ninja_tool = "ninja_tool")
load(
    "@rules_foreign_cc//toolchains/native_tools:native_tools_toolchain.bzl",
    _ToolInfo = "ToolInfo",
    _native_tool_toolchain = "native_tool_toolchain",
)
load("@rules_foreign_cc//tools/build_defs:boost_build.bzl", _boost_build = "boost_build")
load("@rules_foreign_cc//tools/build_defs:cmake.bzl", _cmake = "cmake")
load("@rules_foreign_cc//tools/build_defs:configure.bzl", _configure_make = "configure_make")
load(
    "@rules_foreign_cc//tools/build_defs:framework.bzl",
    _ConfigureParameters = "ConfigureParameters",
    _ForeignCcArtifact = "ForeignCcArtifact",
    _ForeignCcDeps = "ForeignCcDeps",
    _InputFiles = "InputFiles",
    _WrappedOutputs = "WrappedOutputs",
)
load("@rules_foreign_cc//tools/build_defs:make.bzl", _make = "make")
load("@rules_foreign_cc//tools/build_defs:ninja.bzl", _ninja = "ninja")

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
ConfigureParameters = _ConfigureParameters

# buildifier: disable=name-conventions
ForeignCcArtifact = _ForeignCcArtifact

# buildifier: disable=name-conventions
ForeignCcDeps = _ForeignCcDeps

# buildifier: disable=name-conventions
InputFiles = _InputFiles

# buildifier: disable=name-conventions
WrappedOutputs = _WrappedOutputs

# buildifier: disable=name-conventions
ToolInfo = _ToolInfo
