#!/bin/bash
# Shared runner for integration scenarios. Invoked by
# rules_bazel_integration_test for each scenario target.
#
# Required env (set by bazel_integration_test):
#   BIT_WORKSPACE_DIR - path to the scenario's workspace directory
#   BIT_BAZEL_BINARY - path to the bazel binary to run
# Required env (set by the scenario's `env = {...}`):
#   SCENARIO - scenario name (informational)
#   EXPECT_BUILD - target to build (must succeed)
#   OUTER_BZLMOD - "1" if the outer (this) Bazel had bzlmod enabled, else "0".
#                  Computed in BUILD.bazel via `"@@" in str(Label(...))`. We
#                  run the inner build in the matching pure mode so a local
#                  `bazel test --enable_workspace` exercises the WORKSPACE path
#                  and a bzlmod build exercises the MODULE.bazel path. The
#                  scenario dir ships both files; the flags pick which one the
#                  inner Bazel reads. We force a pure mode (never mixed) so a
#                  stray WORKSPACE can't silently satisfy something the
#                  MODULE.bazel path is supposed to provide.
set -euo pipefail

# On the RBE lane, bazelci.py injects
# `--action_env=BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN=1` so the OUTER build uses the
# hermetic RBE-container C++ toolchain (`--crosstool_top=@buildkite_config//...`)
# instead of autodetecting one. That env var lands in this test action's
# environment and would otherwise be inherited by the inner Bazel below. But the
# inner build is `no-remote-exec`: it runs locally on the agent and has no
# `--crosstool_top`, so it MUST autodetect the agent's local C++ toolchain.
# Inheriting the var suppresses that autodetection and the inner build dies with
# "No matching toolchains found for @@bazel_tools//tools/cpp:toolchain_type". Drop
# it so the inner build detects the local toolchain (the agent has one -- the
# non-RBE Ubuntu lanes build identically).
unset BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN

if [[ "${OUTER_BZLMOD}" == "1" ]]; then
  # --lockfile_mode=error enforces the committed MODULE.bazel.lock: if rfcc's
  # resolution drifts, the build fails instead of silently rewriting it (same
  # as the parent repo's CI). Regenerate with, from this scenario dir:
  #   USE_BAZEL_VERSION=8.6.0 bazel mod deps --enable_bzlmod --noenable_workspace
  MODE_FLAGS=(--enable_bzlmod --noenable_workspace --lockfile_mode=error)
else
  MODE_FLAGS=(--noenable_bzlmod --enable_workspace)
fi

cd "${BIT_WORKSPACE_DIR}"
echo ">> ${SCENARIO} (OUTER_BZLMOD=${OUTER_BZLMOD}): bazel build ${MODE_FLAGS[*]} ${EXPECT_BUILD}"
"${BIT_BAZEL_BINARY}" build "${MODE_FLAGS[@]}" "${EXPECT_BUILD}"
echo ">> ${SCENARIO}: PASS"
