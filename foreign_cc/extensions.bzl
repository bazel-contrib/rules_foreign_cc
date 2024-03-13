"""Entry point for extensions used by bzlmod."""

load("//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")
load("//toolchains:prebuilt_toolchains.bzl", "prebuilt_toolchains")

_DEFAULT_CMAKE_VERSION = "3.23.2"
_DEFAULT_NINJA_VERSION = "1.11.1"

cmake_toolchain_version = tag_class(attrs = {
    "version": attr.string(doc = "The cmake version", default = _DEFAULT_CMAKE_VERSION),
})

ninja_toolchain_version = tag_class(attrs = {
    "version": attr.string(doc = "The ninja version", default = _DEFAULT_NINJA_VERSION),
})

def _init(module_ctx):
    rules_foreign_cc_dependencies(
        register_toolchains = False,
        register_built_tools = True,
        register_default_tools = False,
        register_preinstalled_tools = False,
        register_built_pkgconfig_toolchain = True,
    )

    cmake_version = _DEFAULT_CMAKE_VERSION
    ninja_version = _DEFAULT_NINJA_VERSION

    # Traverse all modules starting from the root one (the first in
    # module_ctx.modules). The first occurrence of cmake or ninja tag wins.
    # Multiple versions requested from the same module are rejected.
    for mod in module_ctx.modules:
        cmake_versions_count = len(mod.tags.cmake)
        if cmake_versions_count == 1:
            cmake_version = mod.tags.cmake[0].version
            break
        elif cmake_versions_count > 1:
            fail("More than one cmake version requested: {}".format(mod.tags.cmake))

    for mod in module_ctx.modules:
        ninja_versions_count = len(mod.tags.ninja)
        if ninja_versions_count == 1:
            ninja_version = mod.tags.ninja[0].version
            break
        elif ninja_versions_count > 1:
            fail("More than one ninja version requested: {}".format(mod.tags.ninja))

    prebuilt_toolchains(
        cmake_version = cmake_version,
        ninja_version = ninja_version,
        register_toolchains = False,
    )

tools = module_extension(
    implementation = _init,
    tag_classes = {
        "cmake": cmake_toolchain_version,
        "ninja": ninja_toolchain_version,
    },
)
