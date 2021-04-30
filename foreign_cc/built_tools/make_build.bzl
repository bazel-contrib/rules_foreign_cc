""" Rule for building GNU Make from sources. """

load(
    "//foreign_cc/built_tools/private:built_tools_framework.bzl",
    "FOREIGN_CC_BUILT_TOOLS_ATTRS",
    "FOREIGN_CC_BUILT_TOOLS_HOST_FRAGMENTS",
    "built_tool_rule_impl",
)
load("//foreign_cc/private/framework:helpers.bzl", "os_name")

def _make_tool_impl(ctx):
    script = [
        "./configure --disable-dependency-tracking --prefix=$$INSTALLDIR$$",
        "./build.sh",
    ]

    if "win" in os_name(ctx):
        script.extend([
            "./make.exe install",
        ])
    else:
        script.extend([
            "./make install",
        ])

    return built_tool_rule_impl(
        ctx,
        script,
        ctx.actions.declare_directory("make"),
        "BootstrapGNUMake",
    )

make_tool = rule(
    doc = "Rule for building Make. Invokes configure script and make install.",
    attrs = FOREIGN_CC_BUILT_TOOLS_ATTRS,
    host_fragments = FOREIGN_CC_BUILT_TOOLS_HOST_FRAGMENTS,
    output_to_genfiles = True,
    implementation = _make_tool_impl,
    toolchains = [
        str(Label("//foreign_cc/private/framework:shell_toolchain")),
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)
