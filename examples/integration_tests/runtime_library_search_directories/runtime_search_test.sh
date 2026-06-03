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

if [[ "$#" -lt 2 ]]; then
  echo "usage: $0 <rule-family> <binary-runfile-path> [runfile-path ...]" >&2
  exit 1
fi

family="$1"
shift

binary_runfile_path=""
for arg in "$@"; do
  read -r -a candidates <<< "$arg"
  for candidate in "${candidates[@]}"; do
    case "$candidate" in
      */runtime_app)
        binary_runfile_path="$candidate"
        break 2
        ;;
    esac
  done
done

if [[ -z "$binary_runfile_path" ]]; then
  echo "runtime test binary runfile path not found in: $*" >&2
  exit 1
fi

binary="$(rlocation "$binary_runfile_path")"
if [[ -z "$binary" || ! -x "$binary" ]]; then
  echo "runtime test binary is not executable: $binary_runfile_path" >&2
  exit 1
fi

stdout_file="$TEST_TMPDIR/runtime-search-stdout.txt"
stderr_file="$TEST_TMPDIR/runtime-search-stderr.txt"

set +e
env -u LD_LIBRARY_PATH -u DYLD_LIBRARY_PATH "$binary" >"$stdout_file" 2>"$stderr_file"
status="$?"
set -e

if [[ "$status" -ne 0 ]]; then
  echo "runtime test binary failed with exit code $status" >&2
  cat "$stderr_file" >&2
  exit "$status"
fi

expected="$family: expected libmiddle loaded through rpath -> expected libleaf loaded through rpath"
actual="$(cat "$stdout_file")"

if [[ "$actual" != "$expected" ]]; then
  echo "unexpected runtime marker" >&2
  echo "expected: $expected" >&2
  echo "actual:   $actual" >&2
  cat "$stderr_file" >&2
  exit 1
fi
