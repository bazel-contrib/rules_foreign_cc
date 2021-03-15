""" Rule for building Ninja from sources. """

load(
    "//foreign_cc/built_tools/private:built_tools_framework.bzl",
    "FOREIGN_CC_BUILT_TOOLS_ATTRS",
    "FOREIGN_CC_BUILT_TOOLS_HOST_FRAGMENTS",
    "built_tool_rule_impl",
)

def _ninja_tool_impl(ctx):
    script = [
        "./configure.py --bootstrap",
        # TODO: Reduce unnecessary copys and only keep what's required
        "##copy_dir_contents_to_dir## $$BUILD_TMPDIR$$ $$INSTALLDIR$$",
    ]

    return built_tool_rule_impl(
        ctx,
        script,
        ctx.actions.declare_directory("ninja"),
        "BootstrapNinjaBuild",
    )

ninja_tool = rule(
    doc = "Rule for building Ninja. Invokes configure script.",
    attrs = FOREIGN_CC_BUILT_TOOLS_ATTRS,
    host_fragments = FOREIGN_CC_BUILT_TOOLS_HOST_FRAGMENTS,
    output_to_genfiles = True,
    implementation = _ninja_tool_impl,
    toolchains = [
        str(Label("//foreign_cc/private/shell_toolchain/toolchains:shell_commands")),
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)
