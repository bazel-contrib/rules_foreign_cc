workspace(name = "rules_foreign_cc")

load("//:workspace_definitions.bzl", "rules_foreign_cc_dependencies")

rules_foreign_cc_dependencies()

local_repository(
    name = "rules_foreign_cc_tests",
    path = "examples",
)

register_toolchains(
    "@rules_foreign_cc_tests//:built_cmake_toolchain",
    "@rules_foreign_cc_tests//:built_ninja_toolchain_osx",
    "@rules_foreign_cc_tests//:built_ninja_toolchain_linux",
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

android_sdk_repository(
    name = "androidsdk",
)

android_ndk_repository(
    name = "androidndk",
)

# Google Maven Repository
GMAVEN_TAG = "20180625-1"

http_archive(
    name = "gmaven_rules",
    strip_prefix = "gmaven_rules-%s" % GMAVEN_TAG,
    url = "https://github.com/bazelbuild/gmaven_rules/archive/%s.tar.gz" % GMAVEN_TAG,
)

load("@gmaven_rules//:gmaven.bzl", "gmaven_rules")

gmaven_rules()

load("@rules_foreign_cc_tests//:examples_repositories.bzl", "include_examples_repositories")

include_examples_repositories()
