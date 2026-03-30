"""Module extensions for the third_party examples workspace."""

load("@bazel_features//:features.bzl", "bazel_features")
load("//:repositories.bzl", "repositories")

def _third_party_impl(module_ctx):
    repositories()

    if bazel_features.external_deps.extension_metadata_has_reproducible:
        return module_ctx.extension_metadata(reproducible = True)
    else:
        return None

third_party = module_extension(
    implementation = _third_party_impl,
)
