"""Detect whether the outer Bazel has bzlmod enabled.

Canonical repo labels are spelled "@@..." only under bzlmod, so this is true
in the bzlmod and mixed lanes and false in the workspaces lane. It can't tell
bzlmod-only from mixed, but the integration test doesn't need to: it always
drives the inner build to a pure mode. (Same trick as
examples/third_party/bzlmod_enabled.bzl, which lives in a separate workspace.)
"""

BZLMOD_ENABLED = "@@" in str(Label("//:unused"))
