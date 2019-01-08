""" Rule for building Ninja from sources. """

load("//tools/build_defs:detect_root.bzl", "detect_root")

def _ninja_tool(ctx):
    root = detect_root(ctx.attr.ninja_srcs)

    ninja = ctx.actions.declare_directory("ninja")
    script_text = "\n".join([
        "mkdir " + ninja.path,
        "cp -R ./{}/. {}".format(root, ninja.path),
        "cd " + ninja.path,
        "./configure.py --bootstrap",
    ])

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
)
