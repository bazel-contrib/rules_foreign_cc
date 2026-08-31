"""Expose files from a target output group through DefaultInfo for tests."""

def _output_group_file_impl(ctx):
    files = getattr(ctx.attr.target[OutputGroupInfo], ctx.attr.output_group).to_list()
    if not files:
        fail("Expected at least one file in output group {} for {}".format(
            ctx.attr.output_group,
            ctx.attr.target.label,
        ))
    return [DefaultInfo(files = depset(files))]

output_group_file = rule(
    implementation = _output_group_file_impl,
    attrs = {
        "output_group": attr.string(mandatory = True),
        "target": attr.label(mandatory = True),
    },
)
