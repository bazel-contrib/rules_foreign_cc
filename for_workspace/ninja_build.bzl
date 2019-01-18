""" Rule for building Ninja from sources. """

load("//tools/build_defs:detect_root.bzl", "detect_root")
load("@rules_foreign_cc//tools/build_defs:shell_script_helper.bzl", "convert_shell_script")

def _ninja_tool(ctx):
    root = detect_root(ctx.attr.ninja_srcs)

    ninja = ctx.actions.declare_directory("ninja")
    script = [
        "##mkdirs## " + ninja.path,
        "##copy_dir_contents_to_dir## ./{} {}".format(root, ninja.path),
        "cd " + ninja.path,
        "./configure.py --bootstrap",
    ]
    script_text = convert_shell_script(ctx, script)

    ctx.actions.run_shell(
        mnemonic = "BootstrapNinja",
        inputs = ctx.attr.ninja_srcs.files,
        outputs = [ninja],
        tools = [],
        use_default_shell_env = True,
        command = script_text,
        execution_requirements = {"block-network": ""},
    )

    return [DefaultInfo(files = depset([ninja]))]

""" Rule for building Ninja. Invokes configure script and make install.
  Attributes:
    ninja_srcs - target with the Ninja sources
"""
ninja_tool = rule(
    attrs = {
        "ninja_srcs": attr.label(mandatory = True),
    },
    fragments = ["cpp"],
    output_to_genfiles = True,
    implementation = _ninja_tool,
    toolchains = [
        "@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:shell_commands",
    ],
)
