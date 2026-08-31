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

binary=""
for arg in "$@"; do
  if [[ "$arg" == */bin/zlib-example ]]; then
    binary="$(rlocation "$arg")"
    break
  fi
done

if [[ -z "$binary" ]]; then
  echo >&2 "could not find zlib-example in test args"
  exit 1
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
  otool -L "$binary" | grep -q 'libz'
else
  readelf -d "$binary" | grep -q 'Shared library: \[.*libz\.so'
fi
