#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Set by GH actions, see
# https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables
TAG=${GITHUB_REF_NAME}
# The prefix is chosen to match what GitHub generates for source archives
PREFIX="rules_foreign_cc-${TAG}"
ARCHIVE="rules_foreign_cc-$TAG.tar.gz"
git archive --format=tar --prefix="${PREFIX}"/ "${TAG}" | gzip >"$ARCHIVE"
SHA="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"

cat <<EOF
## Using Bzlmod

1. Enable with \`common --enable_bzlmod\` in \`.bazelrc\`.
2. Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "rules_foreign_cc", version = "${TAG}")

# Configure build tool versions (optional)
tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.cmake(version = "3.31.8")  # Optional: specify a different version
use_repo(
    tools,
    "prebuilt_cmake_toolchains",
    "prebuilt_ninja_toolchains",
    "rules_foreign_cc_framework_toolchains",
    "toolchain_hub",
)

register_toolchains(
    "@prebuilt_cmake_toolchains//:all",
    "@prebuilt_ninja_toolchains//:all",
    "@rules_foreign_cc_framework_toolchains//:all",
    "@toolchain_hub//:all",
)
\`\`\`

### Customizing Tool Versions

You can specify custom versions of build tools using the \`tools\` extension:

\`\`\`starlark
tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.cmake(version = "3.30.5")
tools.ninja(version = "1.12.0")
tools.make(version = "4.4.1")
tools.meson(version = "1.5.1")
tools.pkgconfig(version = "0.29.2")
\`\`\`

For more details, see the [Bzlmod documentation](https://bazel-contrib.github.io/rules_foreign_cc/${TAG}/bzlmod.html).

## Using WORKSPACE

Paste this snippet into your \`WORKSPACE.bazel\` file:

\`\`\`starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "rules_foreign_cc",
    sha256 = "${SHA}",
    strip_prefix = "${PREFIX}",
    url = "https://github.com/bazel-contrib/rules_foreign_cc/releases/download/${TAG}/${ARCHIVE}",
)

load("@rules_foreign_cc//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")

# This sets up some common toolchains for building targets. For more details, please see
# https://bazel-contrib.github.io/rules_foreign_cc/${TAG}/flatten.html#rules_foreign_cc_dependencies
rules_foreign_cc_dependencies()

# If you're not already using bazel_skylib, bazel_features or rules_python,
# you'll need to add these calls as well.

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

load("@bazel_features//:deps.bzl", "bazel_features_deps")

bazel_features_deps()

load("@rules_python//python:repositories.bzl", "py_repositories")

py_repositories()

load("@com_google_protobuf//:protobuf_deps.bzl", "protobuf_deps")

protobuf_deps()

EOF

echo "\`\`\`"
