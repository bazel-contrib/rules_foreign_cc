#!/usr/bin/env bash

set -euo pipefail

resolve_manifest_runfile() {
  local logical_path="$1"
  local manifest_line

  manifest_line=$(grep -sm1 "^${logical_path} " "${RUNFILES_MANIFEST_FILE}")
  if [[ -z "${manifest_line}" ]]; then
    return 1
  fi

  printf '%s\n' "${manifest_line#* }"
}

if [[ -n "${RUNFILES_DIR:-}" && -d "${RUNFILES_DIR}" ]]; then
  :
elif [[ -d "$0.runfiles" ]]; then
  RUNFILES_DIR="$0.runfiles"
elif [[ -d "$0.exe.runfiles" ]]; then
  RUNFILES_DIR="$0.exe.runfiles"
elif [[ -f "${RUNFILES_MANIFEST_FILE:-}" ]]; then
  :
elif [[ -f "$0.runfiles_manifest" ]]; then
  RUNFILES_MANIFEST_FILE="$0.runfiles_manifest"
elif [[ -f "$0.exe.runfiles_manifest" ]]; then
  RUNFILES_MANIFEST_FILE="$0.exe.runfiles_manifest"
else
  echo >&2 "ERROR: cannot find Bazel runfiles for $0"
  exit 1
fi

target_path="$TEST_WORKSPACE/$1"
if [[ -n "${RUNFILES_DIR:-}" ]]; then
  exec "${RUNFILES_DIR}/${target_path}"
fi

exec "$(resolve_manifest_runfile "${target_path}")"
