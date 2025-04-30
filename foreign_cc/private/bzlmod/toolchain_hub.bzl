def _hub_repo_impl(rctx):
    if len(rctx.attr.toolchain_names) != len(rctx.attr.toolchain_target):
        fail("toolchain_names and toolchain_target must have the same length.")
    if len(rctx.attr.toolchain_names) != len(rctx.attr.toolchain_types):
        fail("toolchain_names and toolchain_types must have the same length.")

    toolchains = ["toolchain(name = '{}', toolchain = '{}', toolchain_type = '{}')".format(name, target, type) for (name, target, type) in zip(rctx.attr.toolchain_names, rctx.attr.toolchain_target, rctx.attr.toolchain_types)]

    rctx.file("BUILD", "\n".join(toolchains), executable = False)

hub_repo = repository_rule(
    doc = """\
This private rule creates a repo with a BUILD file that containers all the toolchain
rules that have been requested by the user so that the MODULE.bazel file can simply
register `:all` and get all the toolchains registered in a single call.
    """,
    implementation = _hub_repo_impl,
    attrs = {
        "toolchain_names": attr.string_list(
            doc = "The list of toolchains to include in the hub repo.",
            default = [],
        ),
        "toolchain_target": attr.string_list(
            doc = "The list of toolchain targets to include in the hub repo.",
            default = [],
        ),
        "toolchain_types": attr.string_list(
            doc = "The list of toolchain targets to include in the hub repo.",
            default = [],
        ),
        # "_rules_foreign_cc_workspace: attr.label(default = Label("//:does_not_matter_what_this_name_is")),
    },
)
