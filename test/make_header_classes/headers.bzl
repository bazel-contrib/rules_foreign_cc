"""Header providers with explicit include-search classifications."""

load("@rules_cc//cc:defs.bzl", "CcInfo")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

def _classified_headers_impl(ctx):
    field = "includes" if ctx.attr.kind == "ordinary" else ctx.attr.kind + "_includes"
    return [CcInfo(compilation_context = cc_common.create_compilation_context(
        headers = depset(ctx.files.hdrs),
        **{field: depset([ctx.files.hdrs[0].dirname])}
    ))]

classified_headers = rule(
    implementation = _classified_headers_impl,
    attrs = {
        "hdrs": attr.label_list(allow_files = [".h"], mandatory = True),
        "kind": attr.string(values = ["ordinary", "system", "quote"]),
    },
)
