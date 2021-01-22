"""A module exporting symbols for Stardoc generation"""

load("@rules_foreign_cc//tools/build_defs:boost_build.bzl", _boost_build = "boost_build")
load("@rules_foreign_cc//tools/build_defs:cmake.bzl", _cmake_external = "cmake_external")
load("@rules_foreign_cc//tools/build_defs:configure.bzl", _configure_make = "configure_make")
load("@rules_foreign_cc//:workspace_definitions.bzl", _rules_foreign_cc_dependencies = "rules_foreign_cc_dependencies")
load("@rules_foreign_cc//tools/build_defs:make.bzl", _make = "make")
load(
    "@rules_foreign_cc//tools/build_defs:framework.bzl",
    _ConfigureParameters = "ConfigureParameters",
    _ForeignCcArtifact = "ForeignCcArtifact",
    _ForeignCcDeps = "ForeignCcDeps",
    _InputFiles = "InputFiles",
    _WrappedOutputs = "WrappedOutputs",
)

# Rules
boost_build = _boost_build
cmake_external = _cmake_external
configure_make = _configure_make
make = _make
rules_foreign_cc_dependencies = _rules_foreign_cc_dependencies

# Providers
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
