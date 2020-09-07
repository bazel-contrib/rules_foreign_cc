toolchain_type(
    name = "cmake_toolchain",
    visibility = ["//visibility:public"],
)

toolchain_type(
    name = "ninja_toolchain",
    visibility = ["//visibility:public"],
)

toolchain_type(
    name = "make_toolchain",
    visibility = ["//visibility:public"],
)

# Preinstalled cmake will always be the default, if toolchain with more exact constraints
# is not defined before; registered from workspace_definitions.bzl#rules_foreign_cc_dependencies
toolchain(
    name = "preinstalled_cmake_toolchain",
    toolchain = "@rules_foreign_cc//tools/build_defs/native_tools:preinstalled_cmake",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:cmake_toolchain",
)

# Preinstalled ninja will always be the default, if toolchain with more exact constraints
# is not defined before; registered from workspace_definitions.bzl#rules_foreign_cc_dependencies
toolchain(
    name = "preinstalled_ninja_toolchain",
    toolchain = "@rules_foreign_cc//tools/build_defs/native_tools:preinstalled_ninja",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:ninja_toolchain",
)

# Preinstalled make will always be the default, if toolchain with more exact constraints
# is not defined before; registered from workspace_definitions.bzl#rules_foreign_cc_dependencies
toolchain(
    name = "preinstalled_make_toolchain",
    toolchain = "@rules_foreign_cc//tools/build_defs/native_tools:preinstalled_make",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:make_toolchain",
)
