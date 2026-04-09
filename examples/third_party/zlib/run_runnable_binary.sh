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
  echo >&2 "usage: run_runnable_binary.sh <runnable> <runtime_library_fragment>"
  exit 1
fi

runnable="$(rlocation "$1")"
runtime_library_fragment="$2"

if [[ -z "$runnable" ]]; then
  echo >&2 "could not resolve runnable target"
  exit 1
fi

loader_output="$(mktemp)"
program_output="$(mktemp)"
cleanup() {
  rm -f "$loader_output" "$program_output"
}
trap cleanup EXIT

case "$OSTYPE" in
  darwin*)
    RFCC_TRACE_LIB_PATH=1 "$runnable" >"$program_output" 2>"$loader_output"
    ;;
  linux-gnu*)
    RFCC_TRACE_LIB_PATH=1 LD_DEBUG=libs "$runnable" >"$program_output" 2>"$loader_output"
    ;;
  *)
    "$runnable" >"$program_output" 2>"$loader_output"
    ;;
esac

cat "$program_output"

case "$OSTYPE" in
  msys*|cygwin*)
    # Provenance checks are less useful here, and Bazel's Windows DLL/runtime
    # handling still has known gaps in released versions.
    ;;
  darwin*)
    if [[ -n "$runtime_library_fragment" ]]; then
      lib_path_value="$(grep '^RFCC_RUNNABLE_LIB_PATH_VALUE=' "$loader_output" || true)"
      [[ -n "$lib_path_value" ]] || {
        cat "$loader_output" >&2
        exit 1
      }
      grep -Fq "$runtime_library_fragment" <<<"$lib_path_value" || {
        cat "$loader_output" >&2
        exit 1
      }
    fi
    ;;
  *)
    if [[ -n "$runtime_library_fragment" ]]; then
      loaded_libraries="$(grep -F "$runtime_library_fragment" "$loader_output" || true)"
      [[ -n "$loaded_libraries" ]] || {
        cat "$loader_output" >&2
        exit 1
      }
      grep -Eq '(/external/|/_solib|\.runfiles/)' <<<"$loaded_libraries" || {
        cat "$loader_output" >&2
        exit 1
      }
    fi
    ;;
esac
