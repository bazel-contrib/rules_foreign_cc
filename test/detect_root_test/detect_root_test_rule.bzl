"""A helper rule for testing detect_root function."""

load("@rules_foreign_cc//tools/build_defs:detect_root.bzl", "detect_root")

def _impl(ctx):
    detected_root = detect_root(ctx.attr.srcs)
    out = ctx.actions.declare_file(ctx.attr.out)
    ctx.actions.write(
        output = out,
        content = detected_root,
    )
    return [DefaultInfo(files = depset([out]))]

detect_root_test_rule = rule(
    implementation = _impl,
    attrs = {
        "srcs": attr.label(mandatory = True),
        "out": attr.string(mandatory = True),
    },
)
