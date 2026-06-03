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
  echo >&2 "usage: linkage_test.sh <linkage-manifest-runfile-path>"
  exit 1
fi

manifest="$(rlocation "$1")"
if [[ -z "$manifest" || ! -f "$manifest" ]]; then
  echo >&2 "linkage manifest not found: $1"
  exit 1
fi

: "${TEST_TMPDIR:?TEST_TMPDIR must be set by the Bazel test environment}"

cleanup_files=()
cleanup_outputs() {
  if ((${#cleanup_files[@]})); then
    rm -f "${cleanup_files[@]}"
  fi
}
trap cleanup_outputs EXIT

is_shared_candidate() {
  case "$(basename "$1")" in
    *.so|*.so.*|*.dylib|*.dll)
      return 0
      ;;
  esac
  return 1
}

resolve_inspect_file() {
  local inspect_name="$1"
  local candidate_blob="$2"
  local candidate
  local resolved

  for candidate in $candidate_blob; do
    case "$inspect_name" in
      app)
        is_shared_candidate "$candidate" && continue
        ;;
      libarchive)
        is_shared_candidate "$candidate" || continue
        ;;
      *)
        echo >&2 "unknown inspect target: $inspect_name"
        exit 1
        ;;
    esac

    resolved="$(rlocation "$candidate")"
    if [[ -n "$resolved" && -f "$resolved" ]]; then
      printf '%s\n' "$resolved"
      return
    fi
  done

  echo >&2 "could not resolve inspect file for $inspect_name"
  echo >&2 "candidates: $candidate_blob"
  exit 1
}

inspect_dynamic_deps() {
  local inspect_file="$1"
  local output_file="$2"
  local objdump_path

  case "$OSTYPE" in
    darwin*)
      otool -L "$inspect_file" >"$output_file"
      ;;
    msys*|cygwin*)
      inspect_file="$(objdump_input_path "$inspect_file")"
      objdump_path="$(find_objdump)"
      "$objdump_path" -p "$inspect_file" >"$output_file" || true
      ;;
    *)
      readelf -d "$inspect_file" >"$output_file"
      ;;
  esac
}

dependency_rows() {
  local output_file="$1"

  case "$OSTYPE" in
    darwin*)
      tail -n +2 "$output_file"
      ;;
    msys*|cygwin*)
      grep -E 'DLL Name:' "$output_file" || true
      ;;
    *)
      grep -E 'Shared library:' "$output_file" || true
      ;;
  esac
}

objdump_input_path() {
  local inspect_file="$1"
  local resolved

  if command -v cygpath >/dev/null; then
    inspect_file="$(cygpath -u "$inspect_file" 2>/dev/null || printf '%s\n' "$inspect_file")"
  fi

  if command -v readlink >/dev/null; then
    resolved="$(readlink -f "$inspect_file" 2>/dev/null || true)"
    if [[ -n "$resolved" ]]; then
      inspect_file="$resolved"
    fi
  fi

  printf '%s\n' "$inspect_file"
}

find_objdump() {
  local path

  for path in objdump x86_64-w64-mingw32-objdump; do
    if command -v "$path" >/dev/null; then
      command -v "$path"
      return
    fi
  done

  echo >&2 "objdump not found; add objdump or x86_64-w64-mingw32-objdump to PATH"
  exit 1
}

shared_pattern_for() {
  local library="$1"

  case "$OSTYPE:$library" in
    darwin*:libarchive)
      echo 'libarchive.*\.dylib'
      ;;
    darwin*:zlib)
      echo 'libz.*\.dylib'
      ;;
    msys*:libarchive|cygwin*:libarchive)
      echo 'archive.*\.dll'
      ;;
    msys*:zlib|cygwin*:zlib)
      echo 'zlib1\.dll'
      ;;
    *:libarchive)
      echo 'Shared library: \[.*libarchive.*\.so'
      ;;
    *:zlib)
      echo 'Shared library: \[.*libz\.so'
      ;;
    *)
      echo >&2 "unknown logical library: $library"
      exit 1
      ;;
  esac
}

verify_linkage() {
  local inspect_name="$1"
  local expected_linkage="$2"
  local library="$3"
  local candidate_blob="$4"
  local inspect_file
  local output_file
  local pattern

  inspect_file="$(resolve_inspect_file "$inspect_name" "$candidate_blob")"
  output_file="$TEST_TMPDIR/linkage-${inspect_name}-${library}.txt"
  cleanup_files+=("$output_file")
  inspect_dynamic_deps "$inspect_file" "$output_file"
  pattern="$(shared_pattern_for "$library")"

  if [[ "$expected_linkage" == "dynamic" ]]; then
    dependency_rows "$output_file" | grep -Eqi "$pattern" || {
      echo >&2 "$inspect_name should dynamically link $library"
      echo >&2 "inspect file: $inspect_file"
      cat "$output_file" >&2
      exit 1
    }
  elif [[ "$expected_linkage" == "static" ]]; then
    if dependency_rows "$output_file" | grep -Eqi "$pattern"; then
      echo >&2 "$inspect_name should statically link $library"
      echo >&2 "inspect file: $inspect_file"
      cat "$output_file" >&2
      exit 1
    fi
  else
    echo >&2 "unknown linkage mode: $expected_linkage"
    exit 1
  fi

  rm -f "$output_file"
}

while IFS=$'\t' read -r record inspect_name expected_linkage library candidates; do
  case "$record" in
    ""|"#"?*)
      ;;
    check)
      verify_linkage "$inspect_name" "$expected_linkage" "$library" "$candidates"
      ;;
    *)
      echo >&2 "unknown linkage manifest record: $record"
      exit 1
      ;;
  esac
done <"$manifest"
