#!/usr/bin/env bash

# --- begin runfiles.bash initialization v2 ---
# See https://github.com/bazelbuild/bazel/blob/master/tools/bash/runfiles/runfiles.bash
set -uo pipefail; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v2 ---

set -euo pipefail

runfiles_export_envvars

if [ "$( uname )" == "Linux" ]; then
  export LD_LIBRARY_PATH=
  for manifest in $( cut -f2 -d' ' "${RUNFILES_MANIFEST_FILE}" | grep -E '.LD_LIBRARY_PATH$' ); do
    for rel in $( cat "$manifest" ); do
      LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$PWD/$rel"
    done
  done
fi

exec $@
