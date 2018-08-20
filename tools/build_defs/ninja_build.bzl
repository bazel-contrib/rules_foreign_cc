load("//tools/build_defs:framework.bzl", "detect_root")

def _ninja_tool(ctx):
    root = detect_root(ctx.attr.ninja_srcs)

    ninja = ctx.actions.declare_directory("ninja")
    script_text = "\n".join([
        "mkdir " + ninja.path,
        "cp -r -L ./{}/** {}".format(root, ninja.path),
        "cd " + ninja.path,
        "pwd",
        "./configure.py --bootstrap",
    ])

    ctx.actions.run_shell(
        mnemonic = "BootsrapNinja",
        inputs = ctx.attr.ninja_srcs.files,
        outputs = [ninja],
        tools = [],
        use_default_shell_env = True,
        command = script_text,
        execution_requirements = {"block-network": ""},
    )

    return [DefaultInfo(files = depset([ninja]))]

ninja_tool = rule(
    attrs = {
        "ninja_srcs": attr.label(mandatory = True),
    },
    fragments = ["cpp"],
    output_to_genfiles = True,
    implementation = _ninja_tool,
)
