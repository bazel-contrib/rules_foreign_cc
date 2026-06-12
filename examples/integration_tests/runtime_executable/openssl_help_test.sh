#!/usr/bin/env bash

set -euo pipefail

set +u
f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -d ' ' -f 2-)" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -d ' ' -f 2-)" 2>/dev/null || {
    echo >&2 "cannot find $f"
    exit 1
  }
set -u

if [[ "$#" -ne 1 ]]; then
  echo "usage: $0 <openssl-runfile-path>" >&2
  exit 1
fi

openssl="$(rlocation "$1")"
if [[ -z "$openssl" || ! -x "$openssl" ]]; then
  echo "openssl runtime executable is not executable: $1" >&2
  exit 1
fi

exec "$openssl" help
