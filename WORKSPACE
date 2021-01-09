workspace(name = "rules_foreign_cc")

load("//:workspace_definitions.bzl", "rules_foreign_cc_dependencies")

local_repository(
    name = "rules_foreign_cc_tests",
    path = "examples",
)

rules_foreign_cc_dependencies([
    "@rules_foreign_cc_tests//:built_ninja_toolchain_osx",
    "@rules_foreign_cc_tests//:built_ninja_toolchain_linux",
])

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

android_sdk_repository(
    name = "androidsdk",
)

android_ndk_repository(
    name = "androidndk",
)

# TODO(jin): replace legacy gmaven_rules targets with `maven_install` from the new rules_jvm_external
RULES_JVM_EXTERNAL_TAG = "1.0"

RULES_JVM_EXTERNAL_SHA = "48e0f1aab74fabba98feb8825459ef08dcc75618d381dff63ec9d4dd9860deaa"

http_archive(
    name = "gmaven_rules",
    sha256 = RULES_JVM_EXTERNAL_SHA,
    strip_prefix = "rules_jvm_external-%s" % RULES_JVM_EXTERNAL_TAG,
    url = "https://github.com/bazelbuild/rules_jvm_external/archive/%s.zip" % RULES_JVM_EXTERNAL_TAG,
)

load("@gmaven_rules//:gmaven.bzl", "gmaven_rules")

gmaven_rules()

load("@rules_foreign_cc_tests//:examples_repositories.bzl", "include_examples_repositories")

include_examples_repositories()
