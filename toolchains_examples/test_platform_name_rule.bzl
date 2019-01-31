load("@rules_foreign_cc//tools/build_defs:shell_script_helper.bzl", "os_name")

def _test_platform_name(ctx):
    os_name_ = os_name(ctx)
    print("OS name: " + os_name_)
    if os_name_ != ctx.attr.expected:
        fail("Expected '{}', but was '{}'".format(ctx.attr.expected, os_name_))

    out = ctx.actions.declare_file("out.txt")
    ctx.actions.write(out, os_name_)
    return [DefaultInfo(files = depset(direct = [out]))]

test_platform_name = rule(
    implementation = _test_platform_name,
    attrs = {
        "expected": attr.string(),
    },
    toolchains = ["@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:shell_commands"],
)
