"""This file contains rules for configuration transitions"""

load("//foreign_cc:providers.bzl", "ForeignCcDepsInfo")

def _extra_toolchains_transition_impl(settings, attrs):
    return {"//command_line_option:extra_toolchains": attrs.extra_toolchains + settings["//command_line_option:extra_toolchains"]}

_extra_toolchains_transition = transition(
    implementation = _extra_toolchains_transition_impl,
    inputs = ["//command_line_option:extra_toolchains"],
    outputs = ["//command_line_option:extra_toolchains"],
)

def _extra_toolchains_transitioned_foreign_cc_target_impl(ctx):
    # Return the providers from the transitioned foreign_cc target
    return [
        ctx.attr.target[DefaultInfo],
        ctx.attr.target[CcInfo],
        ctx.attr.target[ForeignCcDepsInfo],
        ctx.attr.target[OutputGroupInfo],
    ]

extra_toolchains_transitioned_foreign_cc_target = rule(
    doc = "A rule for adding extra toolchains to consider when building the given target",
    implementation = _extra_toolchains_transitioned_foreign_cc_target_impl,
    cfg = _extra_toolchains_transition,
    attrs = {
        "extra_toolchains": attr.string_list(
            doc = "Additional toolchains to consider",
            mandatory = True,
        ),
        "target": attr.label(
            doc = "The target to build after considering the extra toolchains",
            providers = [ForeignCcDepsInfo],
            mandatory = True,
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    incompatible_use_toolchain_transition = True,
)

def make_variant(name, rule, toolchain, **kwargs):
    """ Wrapper macro around foreign cc rules to force usage of the given make variant toolchain.

    Args:
        name: The target name
        rule: The foreign cc rule to instantiate, e.g. configure_make
        toolchain: The desired make variant toolchain to use, e.g. @rules_foreign_cc//toolchains:preinstalled_nmake_toolchain
        **kwargs: Remaining keyword arguments
    """

    make_variant_target_name = name + "_"

    tags = kwargs.pop("tags", [])

    rule(
        name = make_variant_target_name,
        tags = tags + ["manual"],
        **kwargs
    )

    extra_toolchains_transitioned_foreign_cc_target(
        name = name,
        extra_toolchains = [toolchain],
        target = make_variant_target_name,
        tags = tags,
    )
