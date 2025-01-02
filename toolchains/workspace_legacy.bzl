"""Legacy utilities for WORKSPACE compatibility"""

_WORKSPACE_FILE = """\
workspace(name = "{}")
"""

def _foreign_cc_toolchain_legacy_repository_impl(repository_ctx):
    repository_ctx.file("BUILD.bazel", repository_ctx.read(repository_ctx.path(repository_ctx.attr._build_file)))
    repository_ctx.file("WORKSPACE.bazel", _WORKSPACE_FILE.format(
        repository_ctx.name,
    ))

foreign_cc_toolchain_legacy_repository = repository_rule(
    doc = "A rule for aliasing rules_foreign_cc toolchains.",
    implementation = _foreign_cc_toolchain_legacy_repository_impl,
    attrs = {
        "_build_file": attr.label(
            default = Label("//toolchains/private:BUILD.legacy.bazel"),
        ),
    },
)
