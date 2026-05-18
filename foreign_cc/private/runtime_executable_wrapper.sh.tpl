#!/usr/bin/env bash

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash

# This wrapper needs to resolve its selected foreign_cc binary from its own
# runfiles. When this wrapper is invoked by another Bazel-built tool, the parent
# may export RUNFILES_DIR or RUNFILES_MANIFEST_FILE for the parent's runfiles
# tree. Prefer the runfiles tree or manifest adjacent to $0 before sourcing
# runfiles.bash.
#
# For example, a parent tool may invoke this wrapper with
# RUNFILES_DIR=.../parent_tool.runfiles. If we keep that inherited value,
# rlocation will look for the selected binary in the parent tool's runfiles
# instead of this wrapper's runfiles.
if [[ -d "$0.runfiles" ]]; then
  export RUNFILES_DIR="$0.runfiles"
  unset RUNFILES_MANIFEST_FILE
elif [[ -f "$0.runfiles_manifest" ]]; then
  export RUNFILES_MANIFEST_FILE="$0.runfiles_manifest"
  unset RUNFILES_DIR
elif [[ -f "$0.exe.runfiles_manifest" ]]; then
  export RUNFILES_MANIFEST_FILE="$0.exe.runfiles_manifest"
  unset RUNFILES_DIR
fi

# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v3 ---

runfiles_export_envvars

binary=""
for candidate in %{binary_runfile_paths}; do
  candidate_binary="$(rlocation "$candidate" 2>/dev/null || true)"
  if [[ -n "$candidate_binary" && -x "$candidate_binary" ]]; then
    binary="$candidate_binary"
    break
  fi
done

if [[ -z "$binary" ]]; then
  printf '%s\n' %{failure_message} >&2
  exit 1
fi

exec "$binary" "$@"
