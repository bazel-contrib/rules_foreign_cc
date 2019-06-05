def _store_bazel_version(repository_ctx):
    bazel_version = native.bazel_version
    if len(bazel_version) == 0:
        print("You're using development build of Bazel, make sure it's recent - version check is disabled.")
    repository_ctx.file("BUILD", "exports_files(['def.bzl'])")
    repository_ctx.file("def.bzl", "BAZEL_VERSION='" + bazel_version + "'")

bazel_version = repository_rule(
    implementation = _store_bazel_version,
)
