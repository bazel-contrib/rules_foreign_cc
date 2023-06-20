"""A helper module containing tools for detecting platform information"""

ForeignCcPlatformInfo = provider(
    doc = "A provider containing information about the current platform",
    fields = {
        "os": "The platform os",
    },
)

def _framework_platform_info_impl(ctx):
    """The implementation of `framework_platform_info`

    Args:
        ctx (ctx): The rule's context object

    Returns:
        list: A provider containing platform info
    """
    return [ForeignCcPlatformInfo(
        os = ctx.attr.os,
    )]

_framework_platform_info = rule(
    doc = "A rule defining platform information used by the foreign_cc framework",
    implementation = _framework_platform_info_impl,
    attrs = {
        "os": attr.string(
            doc = "The platform's operating system",
        ),
    },
)

def framework_platform_info(name = "platform_info"):
    """Define a target containing platform information used in the foreign_cc framework"""
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
    """A helper function for getting the operating system name from a `ForeignCcPlatformInfo` provider

    Args:
        ctx (ctx): The current rule's context object

    Returns:
        str: The string of the current platform
    """
    platform_info = getattr(ctx.attr, "_foreign_cc_framework_platform")
    if not platform_info:
        return "unknown"

    return platform_info[ForeignCcPlatformInfo].os

def target_arch_name(ctx):
    """A helper function for getting the target architecture name based on the constraints

    Args:
        ctx (ctx): The current rule's context object

    Returns:
        str: The string of the current platform
    """
    archs = ["x86_64", "aarch64"]
    for arch in archs:
        constraint = getattr(ctx.attr, "_{}_constraint".format(arch))
        if constraint and ctx.target_platform_has_constraint(constraint[platform_common.ConstraintValueInfo]):
            return arch

    return "unknown"

def target_os_name(ctx):
    """A helper function for getting the target operating system name based on the constraints

    Args:
        ctx (ctx): The current rule's context object

    Returns:
        str: The string of the current platform
    """
    operating_systems = ["android", "linux"]
    for os in operating_systems:
        constraint = getattr(ctx.attr, "_{}_constraint".format(os))
        if constraint and ctx.target_platform_has_constraint(constraint[platform_common.ConstraintValueInfo]):
            return os

    return "unknown"
