""" Rule for building CMake from sources. """

load(
    "//foreign_cc/built_tools/private:built_tools_framework.bzl",
    "FOREIGN_CC_BUILT_TOOLS_ATTRS",
    "FOREIGN_CC_BUILT_TOOLS_HOST_FRAGMENTS",
    "built_tool_rule_impl",
)

def _cmake_tool_impl(ctx):
    script = [
        "./bootstrap --prefix=$$INSTALLDIR$$",
        # TODO: Use make from a toolchain
        "make",
        "make install",
    ]

    return built_tool_rule_impl(
        ctx,
        script,
        ctx.actions.declare_directory("cmake"),
        "BootstrapCMake",
    )

cmake_tool = rule(
    doc = "Rule for building CMake. Invokes bootstrap script and make install.",
    attrs = FOREIGN_CC_BUILT_TOOLS_ATTRS,
    host_fragments = FOREIGN_CC_BUILT_TOOLS_HOST_FRAGMENTS,
    output_to_genfiles = True,
    implementation = _cmake_tool_impl,
    toolchains = [
        str(Label("//foreign_cc/private/shell_toolchain/toolchains:shell_commands")),
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)
