"""Legacy WORKSPACE entry point for prebuilt cmake and ninja toolchains.

This is a thin shim over the per-tool spoke helpers in
``//toolchains/private:binary_spokes.bzl``. It will be deleted when WORKSPACE
support is dropped.
"""

load(
    "//toolchains/private:binary_spokes.bzl",
    "cmake_binary_spokes",
    "ninja_binary_spokes",
)

# buildifier: disable=unnamed-macro
def prebuilt_toolchains(cmake_version, ninja_version, register_toolchains):
    """Register prebuilt cmake and ninja toolchains.

    Args:
        cmake_version: The cmake version to register.
        ninja_version: The ninja version to register.
        register_toolchains: If true, register via native.register_toolchains. Used by bzlmod.
    """
    cmake_binary_spokes(cmake_version, register_toolchains = register_toolchains)
    ninja_binary_spokes(ninja_version, register_toolchains = register_toolchains)
