""" Rule for building GNU Make from sources. """

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load("//foreign_cc/private:detect_root.bzl", "detect_root")
load("//foreign_cc/private:run_shell_file_utils.bzl", "fictive_file_in_genroot")
load("//foreign_cc/private:shell_script_helper.bzl", "convert_shell_script")

def _make_tool(ctx):
    root = detect_root(ctx.attr.make_srcs)

    cc_toolchain = find_cpp_toolchain(ctx)

    # we need this fictive file in the root to get the path of the root in the script
    empty = fictive_file_in_genroot(ctx.actions, ctx.label.name)

    make = ctx.actions.declare_directory("make")
    script = [
        "export EXT_BUILD_ROOT=##pwd##",
        "export INSTALLDIR=$$EXT_BUILD_ROOT$$/" + empty.file.dirname + "/" + ctx.attr.name,
        "export BUILD_TMPDIR=$$INSTALLDIR$$.build_tmpdir",
        "##mkdirs## $$BUILD_TMPDIR$$",
        "##copy_dir_contents_to_dir## ./{} $BUILD_TMPDIR".format(root),
        "cd $$BUILD_TMPDIR$$",
        "./configure --disable-dependency-tracking --prefix=$$EXT_BUILD_ROOT$$/{}".format(make.path),
        "./build.sh",
        "./make install",
        empty.script,
    ]
    script_text = convert_shell_script(ctx, script)

    ctx.actions.run_shell(
        mnemonic = "BootstrapMake",
        inputs = ctx.attr.make_srcs.files,
        outputs = [make, empty.file],
        tools = cc_toolchain.all_files,
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
        "_cc_toolchain": attr.label(default = Label("@bazel_tools//tools/cpp:current_cc_toolchain")),
    },
    host_fragments = ["cpp"],
    output_to_genfiles = True,
    implementation = _make_tool,
    toolchains = [
        "@rules_foreign_cc//foreign_cc/private/shell_toolchain/toolchains:shell_commands",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)
