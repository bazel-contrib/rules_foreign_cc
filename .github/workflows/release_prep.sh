#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Passed as $1 by the reusable release workflow, which invokes this script as
# `.github/workflows/release_prep.sh <tag>`. See
# https://github.com/bazel-contrib/.github/blob/master/.github/workflows/release_ruleset.yaml
TAG=$1
# The prefix is chosen to match what GitHub generates for source archives
PREFIX="rules_foreign_cc-${TAG}"
ARCHIVE="rules_foreign_cc-$TAG.tar.gz"
git archive --format=tar --prefix="${PREFIX}"/ "${TAG}" | gzip >"$ARCHIVE"
SHA="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"

cat <<EOF
## Using Bzlmod

Requires Bazel 8 or newer. Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "rules_foreign_cc", version = "${TAG}")
\`\`\`

That is all you need for the default cmake/ninja toolchains -- \`rules_foreign_cc\`
registers them for you. To pin tool versions or build them from source, see the
[bzlmod hub-and-spoke docs](https://bazel-contrib.github.io/rules_foreign_cc/bzlmod_hub.html).

## Using WORKSPACE

\`WORKSPACE\` is supported on Bazel 7 and 8. Paste this snippet into your
\`WORKSPACE.bazel\` file:

\`\`\`starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "rules_foreign_cc",
    sha256 = "${SHA}",
    strip_prefix = "${PREFIX}",
    url = "https://github.com/bazel-contrib/rules_foreign_cc/releases/download/${TAG}/${ARCHIVE}",
)

load("@rules_foreign_cc//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")

# This sets up some common toolchains for building targets. For the full set of
# options, see the macro's own documentation:
# https://github.com/bazel-contrib/rules_foreign_cc/blob/${TAG}/foreign_cc/repositories.bzl
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

# TODO: add example of how to configure for bzlmod
# awk 'f;/--SNIP--/{f=1}' e2e/smoke/WORKSPACE.bazel
echo "\`\`\`"
