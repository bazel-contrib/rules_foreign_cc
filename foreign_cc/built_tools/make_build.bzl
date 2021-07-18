""" Rule for building GNU Make from sources. """

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load(
    "//foreign_cc/built_tools/private:built_tools_framework.bzl",
    "FOREIGN_CC_BUILT_TOOLS_ATTRS",
    "FOREIGN_CC_BUILT_TOOLS_FRAGMENTS",
    "FOREIGN_CC_BUILT_TOOLS_HOST_FRAGMENTS",
    "built_tool_rule_impl",
)
load("//foreign_cc/private/framework:platform.bzl", "os_name")

def _make_tool_impl(ctx):
    cc_toolchain = find_cpp_toolchain(ctx)

    if "win" in os_name(ctx):
        build_str = "./build_w32.bat --without-guile"
        dist_dir = None

        if cc_toolchain.compiler == "mingw-gcc":
            build_str += " gcc"
            dist_dir = "GccRel"
        else:
            dist_dir = "WinRel"

        script = [
            build_str,
            "mkdir -p $$INSTALLDIR$$/bin",
            "cp -p ./{}/gnumake.exe $$INSTALLDIR$$/bin/make.exe".format(dist_dir),
        ]
    else:
        script = [
            "./configure --disable-dependency-tracking --prefix=$$INSTALLDIR$$",
            "./build.sh",
            "./make install",
        ]

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
    fragments = FOREIGN_CC_BUILT_TOOLS_FRAGMENTS,
    output_to_genfiles = True,
    implementation = _make_tool_impl,
    toolchains = [
        str(Label("//foreign_cc/private/framework:shell_toolchain")),
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)
