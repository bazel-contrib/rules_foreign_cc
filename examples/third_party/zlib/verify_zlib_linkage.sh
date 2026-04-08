#!/usr/bin/env bash

set -euxo pipefail

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

if [[ "$#" -ne 2 ]]; then
  echo >&2 "usage: verify_zlib_linkage.sh <static|dynamic> <inspect>"
  exit 1
fi

expected_linkage="$1"
inspect_binary="$(rlocation "$2")"

if [[ -z "$inspect_binary" ]]; then
  echo >&2 "could not resolve runfiles arguments"
  exit 1
fi

inspection_output="$(mktemp)"
cleanup() {
  rm -f "$inspection_output"
}
trap cleanup EXIT

case "$OSTYPE" in
  darwin*)
    otool -L "$inspect_binary" > "$inspection_output"
    shared_pattern='libz'
    ;;
  msys*|cygwin*)
    objdump -p "$inspect_binary" > "$inspection_output"
    shared_pattern='DLL Name: zlib1\.dll'
    ;;
  *)
    readelf -d "$inspect_binary" > "$inspection_output"
    shared_pattern='Shared library: \[.*libz\.so'
    ;;
esac

if [[ "$expected_linkage" == "dynamic" ]]; then
  grep -Eqi "$shared_pattern" "$inspection_output" || {
    cat "$inspection_output" >&2
    exit 1
  }
elif [[ "$expected_linkage" == "static" ]]; then
  if grep -Eqi "$shared_pattern" "$inspection_output"; then
    cat "$inspection_output" >&2
    exit 1
  fi
else
  echo >&2 "unknown linkage mode: $expected_linkage"
  exit 1
fi
