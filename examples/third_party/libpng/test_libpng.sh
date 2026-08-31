#!/usr/bin/env bash

set -e

# --- begin runfiles.bash initialization ---
f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || {
    echo>&2 "ERROR: cannot find $f"
    exit 1
  }
# --- end runfiles.bash initialization ---

output_dir="${TEST_TMPDIR:-$PWD}"
output_path="${output_dir}/$3"

"$(rlocation "$1")" "$(rlocation "$2")" "$output_path"
test -f "$output_path"
