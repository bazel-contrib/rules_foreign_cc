"""A module defining the various toolchain definitions for `rules_foreign_cc`"""

load(":built_toolchains.bzl", _built_toolchains = "built_toolchains")
load(":prebuilt_toolchains.bzl", _prebuilt_toolchains = "prebuilt_toolchains")

# Re-expose the built toolchains macro
built_toolchains = _built_toolchains

# Re-expose the prebuilt toolchains macro
prebuilt_toolchains = _prebuilt_toolchains

# The set of tools rfcc registers a default toolchain for. This is the
# WORKSPACE-path source of truth for "which tools does rfcc enable by default";
# the bzlmod path mirrors it with default tags in rfcc's MODULE.bazel, and the
# `tools` extension fails if the two sets diverge (see
# _assert_defaults_match_workspace in foreign_cc/extensions.bzl, which sorts
# both sides before comparing -- this list's order is not part of that
# contract). Order here is just registration order, and registration order is
# irrelevant: each tool registers its own distinct toolchain type, so they
# never compete during resolution. Kept alphabetical for readability. nmake is
# deliberately absent: it shares the make_toolchain type and is selected only
# by explicit `toolchain =` label, never registered for constraint resolution.
PREINSTALLED_TOOLS = [
    "autoconf",
    "automake",
    "cmake",
    "m4",
    "make",
    "meson",
    "msbuild",
    "ninja",
    "pkgconfig",
]

# buildifier: disable=unnamed-macro
def preinstalled_toolchains():
    """Register toolchains for various build tools expected to be installed on the exec host"""
    native.register_toolchains(*[
        "@rules_foreign_cc//toolchains:preinstalled_{}_toolchain".format(tool)
        for tool in PREINSTALLED_TOOLS
    ])

def _current_toolchain_impl(ctx):
    toolchain = ctx.toolchains[ctx.attr._toolchain]

    if toolchain.data.target:
        return [
            toolchain,
            platform_common.TemplateVariableInfo(toolchain.data.env),
            DefaultInfo(
                files = toolchain.data.target.files,
                runfiles = toolchain.data.target.default_runfiles,
            ),
        ]
    return [
        toolchain,
        platform_common.TemplateVariableInfo(toolchain.data.env),
        DefaultInfo(),
    ]

# These rules exist so that the current toolchain can be used in the `toolchains` attribute of
# other rules, such as genrule. It allows exposing a <tool>_toolchain after toolchain resolution has
# happened, to a rule which expects a concrete implementation of a toolchain, rather than a
# toochain_type which could be resolved to that toolchain.
#
# See https://github.com/bazelbuild/bazel/issues/14009#issuecomment-921960766
current_cmake_toolchain = rule(
    implementation = _current_toolchain_impl,
    attrs = {
        "_toolchain": attr.string(default = str(Label("//toolchains:cmake_toolchain"))),
    },
    toolchains = [
        str(Label("//toolchains:cmake_toolchain")),
    ],
)

current_make_toolchain = rule(
    implementation = _current_toolchain_impl,
    attrs = {
        "_toolchain": attr.string(default = str(Label("//toolchains:make_toolchain"))),
    },
    toolchains = [
        str(Label("//toolchains:make_toolchain")),
    ],
)

current_ninja_toolchain = rule(
    implementation = _current_toolchain_impl,
    attrs = {
        "_toolchain": attr.string(default = str(Label("//toolchains:ninja_toolchain"))),
    },
    toolchains = [
        str(Label("//toolchains:ninja_toolchain")),
    ],
)

current_meson_toolchain = rule(
    implementation = _current_toolchain_impl,
    attrs = {
        "_toolchain": attr.string(default = str(Label("//toolchains:meson_toolchain"))),
    },
    toolchains = [
        str(Label("//toolchains:meson_toolchain")),
    ],
)

current_autoconf_toolchain = rule(
    implementation = _current_toolchain_impl,
    attrs = {
        "_toolchain": attr.string(default = str(Label("//toolchains:autoconf_toolchain"))),
    },
    toolchains = [
        str(Label("//toolchains:autoconf_toolchain")),
    ],
)

current_automake_toolchain = rule(
    implementation = _current_toolchain_impl,
    attrs = {
        "_toolchain": attr.string(default = str(Label("//toolchains:automake_toolchain"))),
    },
    toolchains = [
        str(Label("//toolchains:automake_toolchain")),
    ],
)

current_m4_toolchain = rule(
    implementation = _current_toolchain_impl,
    attrs = {
        "_toolchain": attr.string(default = str(Label("//toolchains:m4_toolchain"))),
    },
    toolchains = [
        str(Label("//toolchains:m4_toolchain")),
    ],
)

current_pkgconfig_toolchain = rule(
    implementation = _current_toolchain_impl,
    attrs = {
        "_toolchain": attr.string(default = str(Label("//toolchains:pkgconfig_toolchain"))),
    },
    toolchains = [
        str(Label("//toolchains:pkgconfig_toolchain")),
    ],
)

current_msbuild_toolchain = rule(
    implementation = _current_toolchain_impl,
    attrs = {
        "_toolchain": attr.string(default = str(Label("//toolchains:msbuild_toolchain"))),
    },
    toolchains = [
        str(Label("//toolchains:msbuild_toolchain")),
    ],
)
