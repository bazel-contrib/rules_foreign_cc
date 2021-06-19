"""Rules for building foreign_cc targets"""

load(":boost_build.bzl", "boost_build")
load(":cmake.bzl", "cmake")
load(":configure.bzl", "configure_make")
load(":make.bzl", "make")
load(":ninja.bzl", "ninja")
load(":providers.bzl", "ForeignCcDepsInfo")

def foreign_cc_library(name, build_rule, **kwargs):
    """A helper for defining foreign_cc targets

    For a more detailed breakdown of what this rule produces, see the
    documentation for the desired build rule.

    Args:
        name (str): The name of the target being created
        build_rule (str): The build rule to use
        **kwargs: (dict): Keyword arguments for the underlying build rule
    """
    if build_rule == "cmake":
        cmake(
            name = name,
            **kwargs
        )
    elif build_rule == "boost_build":
        boost_build(
            name = name,
            **kwargs
        )
    elif build_rule == "configure_make":
        configure_make(
            name = name,
            **kwargs
        )
    elif build_rule == "make":
        make(
            name = name,
            **kwargs
        )
    elif build_rule == "ninja":
        ninja(
            name = name,
            **kwargs
        )
    else:
        fail("Unexpected build rule: {}".format(build_rule))

def _foreign_cc_binary_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name)
    executable = ctx.attr.target[OutputGroupInfo][ctx.attr.binary or ctx.label.name]
    if len(executable.to_list()) > 1:
        fail("{} was given a target `{}` who's output group `{}` did not contain exactly 1 file: {}".format(
            ctx.label,
            ctx.attr.target,
            ctx.attr.binary or ctx.label.name,
            executable,
        ))
    executable = executable.to_list()[0]

    ctx.actions.symlink(
        output = output,
        target_file = executable,
        is_executable = True,
    )

    return [
        DefaultInfo(
            executable = output,
            runfiles = ctx.attr.target[DefaultInfo].default_runfiles,
        ),
        ctx.attr.target[CcInfo],
    ]

foreign_cc_binary = rule(
    doc = "A rule which extracts binaries from foreign_cc build targets and creates an executable target",
    implementation = _foreign_cc_binary_impl,
    attrs = {
        "binary": attr.string(
            doc = "The target executable from the `out_binaries` attribute of `target`",
        ),
        "target": attr.label(
            doc = "A foreign_cc target",
            providers = [ForeignCcDepsInfo],
            mandatory = True,
        ),
    },
    executable = True,
)
