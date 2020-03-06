load(
    "//tools/build_defs:detect_root.bzl",
    "detect_root",
)
load(
    "@rules_foreign_cc//tools/build_defs:shell_script_helper.bzl",
    "convert_shell_script",
)

def _impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out)
    script_lines = [
        "##mkdirs## aaa",
        "##symlink_contents_to_dir## %s aaa" % ctx.attr.dir1.files.to_list()[0].path,
        "##symlink_contents_to_dir## %s aaa" % ctx.attr.dir2.files.to_list()[0].path,
        "ls -R aaa > %s" % out.path,
    ]
    converted_script = convert_shell_script(ctx, script_lines)
    ctx.actions.run_shell(
        mnemonic = "TestSymlinkContentsToDir",
        inputs = depset(direct = [
            ctx.attr.dir1.files.to_list()[0],
            ctx.attr.dir2.files.to_list()[0],
        ]),
        outputs = [out],
        command = converted_script,
        execution_requirements = {"block-network": ""},
    )
    return [DefaultInfo(files = depset([out]))]

symlink_contents_to_dir_test_rule = rule(
    implementation = _impl,
    attrs = {
        "dir1": attr.label(allow_single_file = True),
        "dir2": attr.label(allow_single_file = True),
        "out": attr.string(),
    },
    toolchains = [
        "@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:shell_commands",
    ],
)
