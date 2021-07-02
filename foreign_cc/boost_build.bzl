""" Rule for building Boost from sources. """

load("//foreign_cc/private:detect_root.bzl", "detect_root")
load(
    "//foreign_cc/private:framework.bzl",
    "CC_EXTERNAL_RULE_ATTRIBUTES",
    "CC_EXTERNAL_RULE_FRAGMENTS",
    "cc_external_rule_impl",
    "create_attrs",
)

def _boost_build_impl(ctx):
    attrs = create_attrs(
        ctx.attr,
        configure_name = "BoostBuild",
        create_configure_script = _create_configure_script,
    )
    return cc_external_rule_impl(ctx, attrs)

def _create_configure_script(configureParameters):
    ctx = configureParameters.ctx
    root = detect_root(ctx.attr.lib_source)

    return [
        "cd $INSTALLDIR",
        "##copy_dir_contents_to_dir## $$EXT_BUILD_ROOT$$/{}/. .".format(root),
        "chmod -R +w .",
        "##enable_tracing##",
        "./bootstrap.sh {}".format(" ".join(ctx.attr.bootstrap_options)),
        "./b2 install {} --prefix=.".format(" ".join(ctx.attr.user_options)),
        "##disable_tracing##",
    ]

def _attrs():
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
    attrs.pop("targets")
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
    implementation = _boost_build_impl,
    toolchains = [
        "@rules_foreign_cc//foreign_cc/private/framework:shell_toolchain",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
    # TODO: Remove once https://github.com/bazelbuild/bazel/issues/11584 is closed and the min supported
    # version is updated to a release of Bazel containing the new default for this setting.
    incompatible_use_toolchain_transition = True,
)
