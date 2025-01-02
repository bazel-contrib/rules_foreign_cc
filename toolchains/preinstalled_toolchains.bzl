"""Preinstalled toolchain definitions"""

_TOOLCHAIN_TEMPLATE = """\
native_tool_toolchain(
    name = "preinstalled_{tool}",
    env = select({{
        "@platforms//os:windows": {{"{env}": "{tool}.exe"}},
        "//conditions:default": {{"{env}": "{tool}"}},
    }}),
    path = select({{
        "@platforms//os:windows": "{tool}.exe",
        "//conditions:default": "{tool}",
    }}),
)

toolchain(
    name = "preinstalled_{tool}_toolchain",
    toolchain = ":preinstalled_{tool}",
    toolchain_type = "@rules_foreign_cc//toolchains:{tool}_toolchain",
)
"""

# Nmake is an odd toolchain for windows that for now
# we handle explicitly
_NMAKE = """\
native_tool_toolchain(
    name = "preinstalled_nmake",
    path = "nmake.exe",
)
"""

# buildifier: disable=unnamed-macro
def preinstalled_toolchains(register_toolchains = True):
    """Register toolchains for various build tools expected to be installed on the exec host.

    Args:
        register_toolchains (bool): Whether or not to register toolchains.

    Returns:
        list: A list of toolchain definitions.
    """
    if register_toolchains:
        native.register_toolchains(
            "@rules_foreign_cc//toolchains:preinstalled_cmake_toolchain",
            "@rules_foreign_cc//toolchains:preinstalled_make_toolchain",
            "@rules_foreign_cc//toolchains:preinstalled_ninja_toolchain",
            "@rules_foreign_cc//toolchains:preinstalled_meson_toolchain",
            "@rules_foreign_cc//toolchains:preinstalled_autoconf_toolchain",
            "@rules_foreign_cc//toolchains:preinstalled_automake_toolchain",
            "@rules_foreign_cc//toolchains:preinstalled_m4_toolchain",
            "@rules_foreign_cc//toolchains:preinstalled_pkgconfig_toolchain",
        )

    toolchains = [
        _TOOLCHAIN_TEMPLATE.format(tool = tool, env = tool.upper())
        for tool in ["m4", "autoconf", "automake"]
    ]

    toolchains.append(_NMAKE)

    return toolchains
