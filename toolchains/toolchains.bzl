"""A module defining the various toolchain definitions for `rules_foreign_cc`"""

load(":built_toolchains.bzl", _built_toolchains = "built_toolchains")
load(":prebuilt_toolchains.bzl", _prebuilt_toolchains = "prebuilt_toolchains")

# Re-expose the built toolchains macro
built_toolchains = _built_toolchains

# Re-expose the prebuilt toolchains macro
prebuilt_toolchains = _prebuilt_toolchains

# buildifier: disable=unnamed-macro
def preinstalled_toolchains():
    """Register toolchains for various build tools expected to be installed on the exec host"""
    native.register_toolchains(
        str(Label("//toolchains:preinstalled_cmake_toolchain")),
        str(Label("//toolchains:preinstalled_make_toolchain")),
        str(Label("//toolchains:preinstalled_ninja_toolchain")),
    )
