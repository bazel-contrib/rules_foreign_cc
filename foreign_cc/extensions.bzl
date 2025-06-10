"""Entry point for extensions used by bzlmod."""

load("//foreign_cc:repositories.bzl", "DEFAULT_CMAKE_VERSION", "DEFAULT_MAKE_VERSION", "DEFAULT_MESON_VERSION", "DEFAULT_NINJA_VERSION", "DEFAULT_PKGCONFIG_VERSION")
load("//foreign_cc/private/bzlmod:toolchain_hub.bzl", "hub_repo")
load("//foreign_cc/private/framework:toolchain.bzl", "register_framework_toolchains")
load("//toolchains:built_toolchains.bzl", "make_toolchain", "meson_toolchain", "pkgconfig_toolchain", cmake_toolchains_src = "cmake_toolchain", ninja_toolchains_src = "ninja_toolchain")
load("//toolchains:prebuilt_toolchains.bzl", "cmake_toolchains", "ninja_toolchains")

cmake_toolchain_version = tag_class(attrs = {
    "version": attr.string(doc = "The cmake version", default = DEFAULT_CMAKE_VERSION),
})

make_toolchain_version = tag_class(attrs = {
    "version": attr.string(doc = "The GNU Make version", default = DEFAULT_MAKE_VERSION),
})

meson_toolchain_version = tag_class(attrs = {
    "version": attr.string(doc = "The meson version", default = DEFAULT_MESON_VERSION),
})

ninja_toolchain_version = tag_class(attrs = {
    "version": attr.string(doc = "The ninja version", default = DEFAULT_NINJA_VERSION),
})

pkgconfig_toolchain_version = tag_class(attrs = {
    "version": attr.string(doc = "The pkgconfig version", default = DEFAULT_PKGCONFIG_VERSION),
})

def _init(module_ctx):
    cmake_registered = False
    make_registered = False
    meson_registered = False
    ninja_registered = False
    pkgconfig_registered = False
    toolchain_names = []
    toolchain_target = []
    toolchain_types = []

    for mod in module_ctx.modules:
        if mod.is_root:
            for toolchain in mod.tags.cmake:
                cmake_toolchains(toolchain.version)
                cmake_toolchains_src(toolchain.version)

                toolchain_names.append("cmake_{}_from_src".format(toolchain.version))
                toolchain_types.append("@rules_foreign_cc//toolchains:cmake_toolchain")
                toolchain_target.append("@cmake_{}_src//:built_cmake".format(toolchain.version))
                cmake_registered = True

            for toolchain in mod.tags.make:
                make_toolchain(toolchain.version)
                toolchain_names.append("make_{}_from_src".format(toolchain.version))
                toolchain_types.append("@rules_foreign_cc//toolchains:make_toolchain")
                toolchain_target.append("@gnumake_{}_src//:built_make".format(toolchain.version))
                make_registered = True

            for toolchain in mod.tags.meson:
                meson_toolchain(toolchain.version)
                toolchain_names.append("meson_{}_from_src".format(toolchain.version))
                toolchain_types.append("@rules_foreign_cc//toolchains:meson_toolchain")
                toolchain_target.append("@meson_{}_src//:built_meson".format(toolchain.version))
                meson_registered = True

            for toolchain in mod.tags.ninja:
                ninja_toolchains(toolchain.version)
                ninja_toolchains_src(toolchain.version)

                toolchain_names.append("ninja_{}_from_src".format(toolchain.version))
                toolchain_types.append("@rules_foreign_cc//toolchains:ninja_toolchain")
                toolchain_target.append("@ninja_{}_src//:built_ninja".format(toolchain.version))
                ninja_registered = True

            for toolchain in mod.tags.pkgconfig:
                pkgconfig_toolchain(toolchain.version)
                toolchain_names.append("pkgconfig_{}_from_src".format(toolchain.version))
                toolchain_types.append("@rules_foreign_cc//toolchains:pkgconfig_toolchain")
                toolchain_target.append("@pkgconfig_{}_src//:built_pkgconfig".format(toolchain.version))
                pkgconfig_registered = True

    if not cmake_registered:
        cmake_toolchains(DEFAULT_CMAKE_VERSION)
        cmake_toolchains_src(DEFAULT_CMAKE_VERSION)

        toolchain_names.append("cmake_{}_from_src".format(DEFAULT_CMAKE_VERSION))
        toolchain_types.append("@rules_foreign_cc//toolchains:cmake_toolchain")
        toolchain_target.append("@cmake_{}_src//:built_cmake".format(DEFAULT_CMAKE_VERSION))

    if not make_registered:
        make_toolchain(DEFAULT_MAKE_VERSION)
        toolchain_names.append("make_{}_from_src".format(DEFAULT_MAKE_VERSION))
        toolchain_types.append("@rules_foreign_cc//toolchains:make_toolchain")
        toolchain_target.append("@gnumake_{}_src//:built_make".format(DEFAULT_MAKE_VERSION))
    if not meson_registered:
        meson_toolchain(DEFAULT_MESON_VERSION)
        toolchain_names.append("meson_{}_from_src".format(DEFAULT_MESON_VERSION))
        toolchain_types.append("@rules_foreign_cc//toolchains:meson_toolchain")
        toolchain_target.append("@meson_{}_src//:built_meson".format(DEFAULT_MESON_VERSION))
    if not ninja_registered:
        ninja_toolchains(DEFAULT_NINJA_VERSION)
        ninja_toolchains_src(DEFAULT_NINJA_VERSION)
        toolchain_names.append("ninja_{}_from_src".format(DEFAULT_NINJA_VERSION))
        toolchain_types.append("@rules_foreign_cc//toolchains:ninja_toolchain")
        toolchain_target.append("@ninja_{}_src//:built_ninja".format(DEFAULT_NINJA_VERSION))
    if not pkgconfig_registered:
        pkgconfig_toolchain(DEFAULT_PKGCONFIG_VERSION)
        toolchain_names.append("pkgconfig_{}_from_src".format(DEFAULT_PKGCONFIG_VERSION))
        toolchain_types.append("@rules_foreign_cc//toolchains:pkgconfig_toolchain")
        toolchain_target.append("@pkgconfig_{}_src//:built_pkgconfig".format(DEFAULT_PKGCONFIG_VERSION))

    register_framework_toolchains(register_toolchains = False)

    hub_repo(name = "toolchain_hub", toolchain_names = toolchain_names, toolchain_target = toolchain_target, toolchain_types = toolchain_types)

tools = module_extension(
    implementation = _init,
    tag_classes = {
        "cmake": cmake_toolchain_version,
        "make": make_toolchain_version,
        "meson": meson_toolchain_version,
        "ninja": ninja_toolchain_version,
        "pkgconfig": pkgconfig_toolchain_version,
    },
)
