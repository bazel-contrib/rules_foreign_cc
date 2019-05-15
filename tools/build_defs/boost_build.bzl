""" Rule for building Boost from sources. """

load(
    "//tools/build_defs:framework.bzl",
    "CC_EXTERNAL_RULE_ATTRIBUTES",
    "cc_external_rule_impl",
    "create_attrs",
)
load("//tools/build_defs:detect_root.bzl", "detect_root")

def _boost_build(ctx):
    attrs = create_attrs(
        ctx.attr,
        configure_name = "BuildBoost",
        create_configure_script = _create_configure_script,
        make_commands = ["./b2 install {} --prefix=.".format(" ".join(ctx.attr.user_options))],
    )
    return cc_external_rule_impl(ctx, attrs)

def _create_configure_script(configureParameters):
    ctx = configureParameters.ctx
    root = detect_root(ctx.attr.lib_source)

    return "\n".join([
        "cd $INSTALLDIR",
        "##copy_dir_contents_to_dir## $$EXT_BUILD_ROOT$$/{}/. .".format(root),
        "./bootstrap.sh {}".format(" ".join(ctx.attr.bootstrap_options)),
    ])

def _attrs():
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
    attrs.update({
        # any additional flags to pass to bootstrap.sh
        "bootstrap_options": attr.string_list(mandatory = False),
        # any additional flags to pass to b2
        "user_options": attr.string_list(mandatory = False),
    })
    return attrs

""" Rule for building Boost. Invokes bootstrap.sh and then b2 install.
  Attributes:
    boost_srcs - target with the boost sources
"""
boost_build = rule(
    attrs = _attrs(),
    fragments = ["cpp"],
    output_to_genfiles = True,
    implementation = _boost_build,
    toolchains = [
        "@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:shell_commands",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)
