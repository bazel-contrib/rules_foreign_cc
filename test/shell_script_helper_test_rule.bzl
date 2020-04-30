load(
    "@rules_foreign_cc//tools/build_defs:shell_script_helper.bzl",
    "convert_shell_script",
)

def _impl(ctx):
    text = convert_shell_script(ctx, ctx.attr.script)
    out = ctx.actions.declare_file(ctx.attr.out)
    ctx.actions.write(
        output = out,
        content = text,
    )
    return [DefaultInfo(files = depset([out]))]

shell_script_helper_test_rule = rule(
    implementation = _impl,
    attrs = {
        "script": attr.string_list(mandatory = True),
        "out": attr.string(mandatory = True),
    },
    toolchains = [
        "@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:shell_commands",
    ],
)
