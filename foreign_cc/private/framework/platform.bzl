"""A helper module containing tools for detecting platform information"""

ForeignCcPlatformInfo = provider(
    doc = "A provider containing information about the current platform",
    fields = {
        "os": "The platform os",
        "path_sep": "The platform's path separator (`:` for unix or `;` for windows)",
    },
)

def _framework_platform_info_impl(ctx):
    return [ForeignCcPlatformInfo(
        os = ctx.attr.os,
        path_sep = ";" if "windows" == ctx.attr.os else ":",
    )]

_framework_platform_info = rule(
    implementation = _framework_platform_info_impl,
    attrs = {
        "os": attr.string(
            doc = "The platform's operating system",
        ),
    },
)

def framework_platform_info(name = "platform_info"):
    """Define a target contianing platform information used in the foreign_cc framework"""
    _framework_platform_info(
        name = name,
        os = select({
            "@platforms//os:android": "android",
            "@platforms//os:freebsd": "freebsd",
            "@platforms//os:ios": "ios",
            "@platforms//os:linux": "linux",
            "@platforms//os:macos": "macos",
            "@platforms//os:none": "none",
            "@platforms//os:openbsd": "openbsd",
            "@platforms//os:qnx": "qnx",
            "@platforms//os:tvos": "tvos",
            "@platforms//os:watchos": "watchos",
            "@platforms//os:windows": "windows",
            "//conditions:default": "unknown",
        }),
        visibility = ["//visibility:public"],
    )

def os_name(ctx):
    """A helper function for getting the operating system name

    Args:
        ctx (ctx): The rule's context object

    Returns:
        str: The string of the current platform
    """
    platform_info = getattr(ctx.attr, "_foreign_cc_framework_platform")
    if not platform_info:
        return "unknown"

    return platform_info[ForeignCcPlatformInfo].os


def path_sep(ctx):
    """A helper function for getting the operating system name

    Args:
        ctx (ctx): The rule's context object

    Returns:
        str: The string of the current platform
    """
    platform_info = getattr(ctx.attr, "_foreign_cc_framework_platform")
    if not platform_info:
        return ":"

    return platform_info[ForeignCcPlatformInfo].path_sep
