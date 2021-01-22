""" Rule for building GNU Make from sources. """

load("//tools/build_defs:detect_root.bzl", "detect_root")
load("@rules_foreign_cc//tools/build_defs:shell_script_helper.bzl", "convert_shell_script")

def _make_tool(ctx):
    root = detect_root(ctx.attr.make_srcs)

    make = ctx.actions.declare_directory("make")
    script = [
        "export BUILD_DIR=##pwd##",
        "export BUILD_TMPDIR=##tmpdir##",
        "##copy_dir_contents_to_dir## ./{} $BUILD_TMPDIR".format(root),
        "cd $$BUILD_TMPDIR$$",
        "./configure --prefix=$$BUILD_DIR$$/{}".format(make.path),
        "./build.sh",
        "./make install",
    ]
    script_text = convert_shell_script(ctx, script)

    ctx.actions.run_shell(
        mnemonic = "BootstrapMake",
        inputs = ctx.attr.make_srcs.files,
        outputs = [make],
        tools = [],
        use_default_shell_env = True,
        command = script_text,
        execution_requirements = {"block-network": ""},
    )

    return [DefaultInfo(files = depset([make]))]

""" Rule for building Make. Invokes configure script and make install.
  Attributes:
    make_srcs - target with the Make sources
"""
make_tool = rule(
    attrs = {
        "make_srcs": attr.label(mandatory = True),
    },
    fragments = ["cpp"],
    output_to_genfiles = True,
    implementation = _make_tool,
    toolchains = [
        "@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:shell_commands",
    ],
)
