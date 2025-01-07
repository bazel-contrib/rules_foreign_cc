"""Entry point for extensions used by bzlmod."""

load("//foreign_cc/private/framework:toolchain.bzl", "register_framework_toolchains")
load(
    "//toolchains:built_toolchains.bzl",
    cmake_toolchain_built = "cmake_toolchain",
    make_toolchain_built = "make_toolchain",
    meson_toolchain_built = "meson_toolchain",
    ninja_toolchain_built = "ninja_toolchain",
    pkgconfig_toolchain_built = "pkgconfig_toolchain",
)
load(
    "//toolchains:prebuilt_toolchains.bzl",
    cmake_toolchain_prebuilt = "cmake_toolchains",
    ninja_toolchain_prebuilt = "ninja_toolchains",
)
load(
    "//toolchains:preinstalled_toolchains.bzl",
    "preinstalled_toolchains",
)

_DEFAULT_CMAKE_VERSION = "3.23.2"
_DEFAULT_NINJA_VERSION = "1.12.1"
_DEFAULT_MESON_VERSION = "1.5.1"
_DEFAULT_MAKE_VERSION = "4.4.1"
_DEFAULT_PKG_CONFIG_VERSION = "0.29.2"

_TOOL_TYPE_PREBUILT = "prebuilt"
_TOOL_TYPE_BUILT = "built"

_tools = tag_class(
    doc = "Tags for defining Foreign Cc toolchains.",
    attrs = {
        "name": attr.string(
            doc = "The name of the tools repository.",
            default = "rules_foreign_cc_toolchains",
        ),
    } | {
        "cmake": attr.string(
            doc = "The cmake version",
            default = _DEFAULT_CMAKE_VERSION,
        ),
        "cmake_tool_type": attr.string(
            doc = "The type of toolchain to use.",
            values = [
                _TOOL_TYPE_PREBUILT,
                _TOOL_TYPE_BUILT,
            ],
            default = _TOOL_TYPE_PREBUILT,
        ),
        "make": attr.string(
            doc = "The make version.",
            default = _DEFAULT_MAKE_VERSION,
        ),
        "make_tool_type": attr.string(
            doc = "The type of toolchain to use.",
            values = [
                _TOOL_TYPE_BUILT,
            ],
            default = _TOOL_TYPE_BUILT,
        ),
        "meson": attr.string(
            doc = "The meson version.",
            default = _DEFAULT_MESON_VERSION,
        ),
        "meson_tool_type": attr.string(
            doc = "The type of toolchain to use.",
            values = [
                _TOOL_TYPE_BUILT,
            ],
            default = _TOOL_TYPE_BUILT,
        ),
        "ninja": attr.string(
            doc = "The ninja version",
            default = _DEFAULT_NINJA_VERSION,
        ),
        "ninja_tool_type": attr.string(
            doc = "The type of toolchain to use.",
            values = [
                _TOOL_TYPE_PREBUILT,
                _TOOL_TYPE_BUILT,
            ],
            default = _TOOL_TYPE_PREBUILT,
        ),
        "pkgconfig": attr.string(
            doc = "The pkgconfig version.",
            default = _DEFAULT_PKG_CONFIG_VERSION,
        ),
        "pkgconfig_tool_type": attr.string(
            doc = "The type of toolchain to use.",
            values = [
                _TOOL_TYPE_BUILT,
            ],
            default = _TOOL_TYPE_BUILT,
        ),
    },
)

_BUILD_FILE = """\
load("@rules_foreign_cc//toolchains/native_tools:native_tools_toolchain.bzl", "native_tool_toolchain")

package(default_visibility = ["//visibility:public"])

{toolchains}
"""

_WORKSPACE_FILE = """\
workspace(name = "{}")
"""

def _foreign_cc_toolchain_repository_impl(repository_ctx):
    repository_ctx.file("BUILD.bazel", _BUILD_FILE.format(
        toolchains = "\n".join(repository_ctx.attr.toolchains),
    ))
    repository_ctx.file("WORKSPACE.bazel", _WORKSPACE_FILE.format(
        repository_ctx.name,
    ))

_foreign_cc_toolchain_repository = repository_rule(
    doc = "A rule for aliasing rules_foreign_cc toolchains.",
    implementation = _foreign_cc_toolchain_repository_impl,
    attrs = {
        "toolchains": attr.string_list(
            doc = "Toolchain definitions to render into the repository.",
            mandatory = True,
        ),
    },
)

def _foreign_cc_impl(module_ctx):
    # Defines `rules_foreign_cc_framework_toolchains` but with bzlmod
    # users are required to register it themselves.
    register_framework_toolchains(
        register_toolchains = False,
    )

    cmake_prebuilt = {}
    cmake_built = {}
    ninja_prebuilt = {}
    ninja_built = {}
    make_built = {}
    pkgconfig_built = {}
    meson_built = {}

    tags = []
    for mod in module_ctx.modules:
        if mod.is_root:
            tags.extend(mod.tags.tools)

    if not tags:
        tags = [struct(
            name = "rules_foreign_cc_toolchains",
            cmake = _DEFAULT_CMAKE_VERSION,
            cmake_tool_type = _TOOL_TYPE_PREBUILT,
            make = _DEFAULT_MAKE_VERSION,
            make_tool_type = _TOOL_TYPE_BUILT,
            meson = _DEFAULT_MESON_VERSION,
            meson_tool_type = _TOOL_TYPE_BUILT,
            ninja = _DEFAULT_NINJA_VERSION,
            ninja_tool_type = _TOOL_TYPE_PREBUILT,
            pkgconfig = _DEFAULT_PKG_CONFIG_VERSION,
            pkgconfig_tool_type = _TOOL_TYPE_BUILT,
        )]

    for tag in tags:
        toolchains = []

        if tag.cmake_tool_type == _TOOL_TYPE_PREBUILT:
            if tag.cmake not in cmake_prebuilt:
                cmake_prebuilt[tag.cmake] = cmake_toolchain_prebuilt(
                    version = tag.cmake,
                    register_toolchains = False,
                )

            toolchains.extend(cmake_prebuilt[tag.cmake])

        elif tag.cmake_tool_type == _TOOL_TYPE_BUILT:
            if tag.cmake not in cmake_built:
                cmake_built[tag.cmake] = cmake_toolchain_built(
                    name = "cmake_{}_src".format(tag.cmake),
                    version = tag.cmake,
                    register_toolchains = False,
                )

            toolchains.extend(cmake_built[tag.cmake])

        if tag.ninja_tool_type == _TOOL_TYPE_PREBUILT:
            if tag.ninja not in ninja_prebuilt:
                ninja_prebuilt[tag.ninja] = ninja_toolchain_prebuilt(
                    version = tag.ninja,
                    register_toolchains = False,
                )

            toolchains.extend(ninja_prebuilt[tag.ninja])

        elif tag.ninja_tool_type == _TOOL_TYPE_BUILT:
            if tag.ninja not in ninja_built:
                ninja_built[tag.ninja] = ninja_toolchain_built(
                    name = "ninja_{}_src".format(tag.ninja),
                    version = tag.ninja,
                    register_toolchains = False,
                )

            toolchains.extend(ninja_built[tag.ninja])

        # The following only support built tools so their values will
        # be directly stored
        if tag.make not in make_built:
            make_built[tag.make] = make_toolchain_built(
                name = "make_{}_src".format(tag.make),
                version = tag.make,
                register_toolchains = False,
            )
        toolchains.extend(make_built[tag.make])

        if tag.pkgconfig not in pkgconfig_built:
            pkgconfig_built[tag.pkgconfig] = pkgconfig_toolchain_built(
                name = "pkgconfig_{}_src".format(tag.pkgconfig),
                version = tag.pkgconfig,
                register_toolchains = False,
            )
        toolchains.extend(pkgconfig_built[tag.pkgconfig])

        if tag.meson not in meson_built:
            meson_built[tag.meson] = meson_toolchain_built(
                name = "meson_{}_src".format(tag.meson),
                version = tag.meson,
                register_toolchains = False,
            )
        toolchains.extend(meson_built[tag.meson])

        toolchains.extend(preinstalled_toolchains(
            register_toolchains = False,
        ))

        _foreign_cc_toolchain_repository(
            name = tag.name,
            toolchains = toolchains,
        )

foreign_cc = module_extension(
    doc = "rules_foreign_cc bzlmod extensions.",
    implementation = _foreign_cc_impl,
    tag_classes = {
        "tools": _tools,
    },
)
