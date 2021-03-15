""" Rule for building Boost from sources. """

load("//foreign_cc/private:detect_root.bzl", "detect_root")
load(
    "//foreign_cc/private:framework.bzl",
    "CC_EXTERNAL_RULE_ATTRIBUTES",
    "CC_EXTERNAL_RULE_FRAGMENTS",
    "cc_external_rule_impl",
    "create_attrs",
)

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

    return struct(
	commands = [
            "cd $INSTALLDIR",
            "##copy_dir_contents_to_dir## $$EXT_BUILD_ROOT$$/{}/. .".format(root),
            "./bootstrap.sh {}".format(" ".join(ctx.attr.bootstrap_options)),
        ],
	files = [],
    )

def _attrs():
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
    attrs.update({
        "bootstrap_options": attr.string_list(
            doc = "any additional flags to pass to bootstrap.sh",
            mandatory = False,
        ),
        "user_options": attr.string_list(
            doc = "any additional flags to pass to b2",
            mandatory = False,
        ),
    })
    return attrs

boost_build = rule(
    doc = "Rule for building Boost. Invokes bootstrap.sh and then b2 install.",
    attrs = _attrs(),
    fragments = CC_EXTERNAL_RULE_FRAGMENTS,
    output_to_genfiles = True,
    implementation = _boost_build,
    toolchains = [
        "@rules_foreign_cc//foreign_cc/private/shell_toolchain/toolchains:shell_commands",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)
