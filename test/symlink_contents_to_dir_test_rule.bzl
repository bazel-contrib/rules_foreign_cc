load(
    "@rules_foreign_cc//tools/build_defs:shell_script_helper.bzl",
    "convert_shell_script",
)
load("@rules_foreign_cc//tools/build_defs:detect_root.bzl", "detect_root", "filter_containing_dirs_from_inputs")

def _impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out)
    dir1 = detect_root(ctx.attr.dir1)
    dir2 = detect_root(ctx.attr.dir2)
    script_lines = [
        "##mkdirs## aaa",
        "##symlink_contents_to_dir## %s aaa" % dir1,
        "##symlink_contents_to_dir## %s aaa" % dir2,
        "ls -R aaa > %s" % out.path,
    ]
    converted_script = convert_shell_script(ctx, script_lines)
    ctx.actions.run_shell(
        mnemonic = "TestSymlinkContentsToDir",
        inputs = depset(
            direct =
                filter_containing_dirs_from_inputs(ctx.attr.dir1.files.to_list()) +
                filter_containing_dirs_from_inputs(ctx.attr.dir2.files.to_list()),
        ),
        outputs = [out],
        command = converted_script,
        execution_requirements = {"block-network": ""},
    )
    return [DefaultInfo(files = depset([out]))]

symlink_contents_to_dir_test_rule = rule(
    implementation = _impl,
    attrs = {
        "dir1": attr.label(allow_files = True),
        "dir2": attr.label(allow_files = True),
        "out": attr.string(),
    },
    toolchains = [
        "@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:shell_commands",
    ],
)
