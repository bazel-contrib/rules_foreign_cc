""" Rule for building GNU Make from sources. """

load("@rules_foreign_cc//tools/build_defs:shell_script_helper.bzl", "convert_shell_script")
load("//tools/build_defs:detect_root.bzl", "detect_root")

def _make_tool(ctx):
    root = detect_root(ctx.attr.make_srcs)

    make = ctx.actions.declare_directory("make")
    script = [
        "export BUILD_DIR=##pwd##",
        "export BUILD_TMPDIR=$${BUILD_DIR}$$.build_tmpdir",
        "##mkdirs## $$BUILD_TMPDIR$$",
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

make_tool = rule(
    doc = "Rule for building Make. Invokes configure script and make install.",
    attrs = {
        "make_srcs": attr.label(
            doc = "target with the Make sources",
            mandatory = True,
        ),
    },
    host_fragments = ["cpp"],
    output_to_genfiles = True,
    implementation = _make_tool,
    toolchains = [
        "@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:shell_commands",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)
