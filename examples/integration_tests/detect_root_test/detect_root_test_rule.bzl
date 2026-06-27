"""A helper rule for testing detect_root function."""

# buildifier: disable=bzl-visibility
load("@rules_foreign_cc//foreign_cc/private:detect_root.bzl", "detect_root")

def _impl(ctx):
    detected_root = detect_root(ctx.attr.srcs)
    out = ctx.actions.declare_file(ctx.attr.out)
    ctx.actions.write(
        output = out,
        content = detected_root + "\n",
    )
    return [DefaultInfo(files = depset([out]))]

detect_root_test_rule = rule(
    implementation = _impl,
    attrs = {
        "out": attr.string(mandatory = True),
        "srcs": attr.label(mandatory = True),
    },
)

def _workspace_root_impl(ctx):
    # Emit bazel's own canonical external root for the repo that `srcs` lives
    # in. The repo's BUILD file sits at that root, so detect_root must report
    # the same path -- giving repo_test an oracle that tracks bazel's repo-name
    # mangling across versions instead of a golden file we re-bless each bump.
    out = ctx.actions.declare_file(ctx.attr.out)
    ctx.actions.write(
        output = out,
        content = ctx.attr.srcs.label.workspace_root + "\n",
    )
    return [DefaultInfo(files = depset([out]))]

workspace_root_rule = rule(
    implementation = _workspace_root_impl,
    attrs = {
        "out": attr.string(mandatory = True),
        "srcs": attr.label(mandatory = True),
    },
)
