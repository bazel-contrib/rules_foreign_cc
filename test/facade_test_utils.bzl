"""Shared test-only helpers for facade parity fixtures."""

load("//foreign_cc:providers.bzl", "ForeignCcFacadeInputsInfo")

def _select_foreign_output_impl(ctx):
    facade_inputs = ctx.attr.src[ForeignCcFacadeInputsInfo]
    candidates = (
        facade_inputs.binary_files +
        facade_inputs.shared_libraries +
        facade_inputs.interface_libraries +
        facade_inputs.static_libraries
    )
    matches = [file for file in candidates if file.basename == ctx.attr.basename]
    if len(matches) != 1:
        fail("Expected exactly one foreign output named `{}` from `{}`, found `{}`".format(
            ctx.attr.basename,
            ctx.attr.src.label,
            [file.basename for file in matches],
        ))

    return [DefaultInfo(files = depset(matches))]

select_foreign_output = rule(
    implementation = _select_foreign_output_impl,
    attrs = {
        "basename": attr.string(mandatory = True),
        "src": attr.label(
            mandatory = True,
            providers = [ForeignCcFacadeInputsInfo],
        ),
    },
)
