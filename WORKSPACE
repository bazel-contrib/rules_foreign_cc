workspace(name = "rules_foreign_cc")

load("//:workspace_definitions.bzl", "rules_foreign_cc_dependencies")

rules_foreign_cc_dependencies()

local_repository(
    name = "rules_foreign_cc_tests",
    path = "examples",
)

load("@rules_foreign_cc_tests//deps:repositories.bzl", examples_repositories = "repositories")

examples_repositories()

android_sdk_repository(
    name = "androidsdk",
)

android_ndk_repository(
    name = "androidndk",
)

load("@rules_foreign_cc_tests//deps:deps_jvm_external.bzl", examples_deps_jvm_external = "deps_jvm_external")

examples_deps_jvm_external()

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()
