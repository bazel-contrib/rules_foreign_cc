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

if [[ "$#" -ne 1 ]]; then
  echo >&2 "expected the shared zlib binary rlocationpath as the only arg"
  exit 1
fi

binary="$(rlocation "$1")"

if [[ -z "$binary" ]]; then
  echo >&2 "could not find zlib-example in test args"
  exit 1
fi

inspection_output="$(mktemp)"
cleanup() {
  rm -f "$inspection_output"
}
trap cleanup EXIT

if [[ "$OSTYPE" == "darwin"* ]]; then
  otool -L "$binary" > "$inspection_output"
  grep -q 'libz' "$inspection_output" || {
    cat "$inspection_output" >&2
    exit 1
  }
elif [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then
  runfiles_root="${RUNFILES_DIR:-}"
  if [[ -z "$runfiles_root" || ! -d "$runfiles_root" ]]; then
    runfiles_root="$(dirname "$binary")"
  fi
  imported_runtime=0
  objdump -p "$binary" > "$inspection_output"

  while IFS= read -r dll; do
    dll_name="$(basename "$dll")"
    if grep -Fqi "DLL Name: $dll_name" "$inspection_output"; then
      imported_runtime=1
      break
    fi
  done < <(find "$runfiles_root" -type f -iname '*.dll')

  if [[ "$imported_runtime" -ne 1 ]]; then
    echo >&2 "could not find an imported staged DLL for $binary"
    find "$runfiles_root" -type f -iname '*.dll' >&2 || true
    cat "$inspection_output" >&2
    exit 1
  fi
else
  readelf -d "$binary" > "$inspection_output"
  grep -q 'Shared library: \[.*libz\.so' "$inspection_output" || {
    cat "$inspection_output" >&2
    exit 1
  }
fi
