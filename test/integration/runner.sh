#!/bin/bash
# Shared runner for bazel-in-bazel integration scenarios. Invoked by
# rules_bazel_integration_test for each scenario target (see scenarios.bzl).
#
# Required env (set by bazel_integration_test):
#   BIT_WORKSPACE_DIR - path to the scenario's workspace directory
#   BIT_BAZEL_BINARY  - path to the bazel binary to run
# Required env (set by the scenario's `env = {...}`):
#   SCENARIO - scenario name (informational)
# Mode env (set by the scenario() macro):
#   DUAL_MODE    - "1" if the scenario ships both MODULE.bazel and
#                  WORKSPACE.bazel and should run in the outer Bazel's mode.
#   OUTER_BZLMOD - "1" if the outer (this) Bazel had bzlmod enabled, else "0".
#                  Only meaningful when DUAL_MODE=1. Computed in BUILD.bazel
#                  via `"@@" in str(Label(...))`. We run the inner build in the
#                  matching pure mode so a local `bazel test --enable_workspace`
#                  exercises the WORKSPACE path and a bzlmod build exercises the
#                  MODULE.bazel path. We force a pure mode (never mixed) so a
#                  stray WORKSPACE can't silently satisfy something the
#                  MODULE.bazel path is supposed to provide.
#   ENFORCE_LOCK - "1" to pass --lockfile_mode=error on the bzlmod inner build,
#                  enforcing a committed MODULE.bazel.lock (same as parent CI).
# Assertion env (at least one of EXPECT_BUILD / EXPECT_BUILD_FAIL /
# EXPECT_CQUERY is REQUIRED; the runner fails if none ran):
#   EXPECT_BUILD             - target to build (must succeed)
#   EXPECT_BUILD_FAIL        - target whose build must fail (non-zero exit);
#                              requires EXPECT_BUILD_FAIL_PATTERN
#   EXPECT_BUILD_FAIL_PATTERN- regex the failing build's output must match
#                              (asserts the failure reason, not just exit code)
#   EXPECT_CQUERY            - cquery expression to run; output is captured
#   EXPECT_STDOUT_PATTERN    - regex that EXPECT_CQUERY's output must match
set -euo pipefail

# On the RBE job, bazelci.py injects
# `--action_env=BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN=1` so the OUTER build uses the
# hermetic RBE-container C++ toolchain (`--crosstool_top=@buildkite_config//...`)
# instead of autodetecting one. That env var lands in this test action's
# environment and would otherwise be inherited by the inner Bazel below. But the
# inner build is `no-remote-exec`: it runs locally on the agent and has no
# `--crosstool_top`, so it MUST autodetect the agent's local C++ toolchain.
# Inheriting the var suppresses that autodetection and the inner build dies with
# "No matching toolchains found for @@bazel_tools//tools/cpp:toolchain_type". Drop
# it so the inner build detects the local toolchain (the agent has one -- the
# non-RBE Ubuntu jobs build identically).
unset BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN

# Pick the inner Bazel's mode. A bzlmod-only scenario always runs pure bzlmod;
# a dual-mode scenario mirrors the outer Bazel's mode.
if [[ "${DUAL_MODE:-0}" == "1" && "${OUTER_BZLMOD:-1}" == "0" ]]; then
  MODE_FLAGS=(--noenable_bzlmod --enable_workspace)
else
  MODE_FLAGS=(--enable_bzlmod --noenable_workspace)
  if [[ "${ENFORCE_LOCK:-0}" == "1" ]]; then
    # --lockfile_mode=error enforces the committed MODULE.bazel.lock: if rfcc's
    # resolution drifts, the build fails instead of silently rewriting it (same
    # as the parent repo's CI). Regenerate with, from this scenario dir:
    #   USE_BAZEL_VERSION=8.6.0 bazel mod deps --enable_bzlmod --noenable_workspace
    MODE_FLAGS+=(--lockfile_mode=error)
  fi
fi

cd "${BIT_WORKSPACE_DIR}"
BAZEL="${BIT_BAZEL_BINARY}"

# Count the recognized assertions that actually ran. A scenario that sets no
# (or a misspelled) EXPECT_* var would otherwise fall through to PASS having
# verified nothing; we fail loudly at the end instead.
assertions=0

if [[ -n "${EXPECT_BUILD:-}" ]]; then
  echo ">> ${SCENARIO}: bazel build ${MODE_FLAGS[*]} ${EXPECT_BUILD}"
  "${BAZEL}" build "${MODE_FLAGS[@]}" "${EXPECT_BUILD}"
  assertions=$((assertions + 1))
fi

if [[ -n "${EXPECT_BUILD_FAIL:-}" ]]; then
  # A failing build must say *why* it failed, or a typo/missing-dep/wrong-label
  # would also fail and let the scenario "pass" for the wrong reason. Require
  # the pattern rather than letting it silently degrade to exit-code-only.
  if [[ -z "${EXPECT_BUILD_FAIL_PATTERN:-}" ]]; then
    echo "FAIL: ${SCENARIO} sets EXPECT_BUILD_FAIL but no EXPECT_BUILD_FAIL_PATTERN"
    exit 1
  fi
  echo ">> ${SCENARIO}: bazel build ${MODE_FLAGS[*]} ${EXPECT_BUILD_FAIL} (expecting failure)"
  # Capture combined output so we can assert on the failure reason.
  set +e
  fail_output="$("${BAZEL}" build "${MODE_FLAGS[@]}" "${EXPECT_BUILD_FAIL}" 2>&1)"
  fail_status=$?
  set -e
  echo "${fail_output}"
  if [[ ${fail_status} -eq 0 ]]; then
    echo "FAIL: build was expected to fail but succeeded"
    exit 1
  fi
  if ! grep -qE "${EXPECT_BUILD_FAIL_PATTERN}" <<<"${fail_output}"; then
    echo "FAIL: expected failure pattern '${EXPECT_BUILD_FAIL_PATTERN}' not found in output"
    exit 1
  fi
  assertions=$((assertions + 1))
fi

if [[ -n "${EXPECT_CQUERY:-}" ]]; then
  echo ">> ${SCENARIO}: bazel cquery ${MODE_FLAGS[*]} ${EXPECT_CQUERY}"
  output="$("${BAZEL}" cquery "${MODE_FLAGS[@]}" "${EXPECT_CQUERY}" 2>&1)"
  echo "${output}"
  if [[ -n "${EXPECT_STDOUT_PATTERN:-}" ]] && ! grep -qE "${EXPECT_STDOUT_PATTERN}" <<<"${output}"; then
    echo "FAIL: expected pattern '${EXPECT_STDOUT_PATTERN}' not found in output"
    exit 1
  fi
  assertions=$((assertions + 1))
fi

if [[ ${assertions} -eq 0 ]]; then
  echo "FAIL: ${SCENARIO} ran no assertions -- set EXPECT_BUILD, EXPECT_BUILD_FAIL, or EXPECT_CQUERY (check for a typo'd env key)"
  exit 1
fi

echo ">> ${SCENARIO}: PASS"
