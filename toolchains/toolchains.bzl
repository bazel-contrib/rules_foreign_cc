"""A module defining the various toolchain definitions for `rules_foreign_cc`"""

load(":prebuilt_toolchains.bzl", _prebuilt_toolchains = "prebuilt_toolchains")

# Re-expose the prebuilt toolchains macro
prebuilt_toolchains = _prebuilt_toolchains

# buildifier: disable=unnamed-macro
def preinstalled_toolchains():
    """Register toolchains for various build tools expected to be installed on the exec host"""
    native.register_toolchains(
        "@rules_foreign_cc//tools/build_defs:preinstalled_cmake_toolchain",
        "@rules_foreign_cc//tools/build_defs:preinstalled_make_toolchain",
        "@rules_foreign_cc//tools/build_defs:preinstalled_ninja_toolchain",
    )
