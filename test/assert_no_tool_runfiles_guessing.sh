#!/usr/bin/env bash
set -euo pipefail

ext_build_root_prefix="\$EXT_BUILD_ROOT/\$EXT_BUILD_ROOT/"
ext_build_deps_prefix="\$EXT_BUILD_ROOT/\$EXT_BUILD_DEPS/"

script=""
for candidate in "$@"; do
  if [[ "$candidate" == *"/build_script.sh" ]]; then
    script="$candidate"
    break
  fi
done

if [[ -z "$script" ]]; then
  echo "expected one generated build_script.sh path in args" >&2
  exit 1
fi

if grep -Fq ".runfiles_manifest" "$script"; then
    echo "unexpected guessed .runfiles_manifest staging in $script" >&2
    exit 1
fi

if grep -Fq ".exe.runfiles_manifest" "$script"; then
  echo "unexpected guessed .exe.runfiles_manifest staging in $script" >&2
  exit 1
fi

if grep -Fq ".runfiles/MANIFEST" "$script"; then
  echo "unexpected explicit runfiles manifest staging in $script" >&2
  exit 1
fi

if grep -Fq ".repo_mapping" "$script"; then
  echo "unexpected repo_mapping staging in $script" >&2
  exit 1
fi

if grep -Fq "$ext_build_root_prefix" "$script"; then
  echo "unexpected doubly-prefixed EXT_BUILD_ROOT staging in $script" >&2
  exit 1
fi

if grep -Fq "$ext_build_deps_prefix" "$script"; then
  echo "unexpected EXT_BUILD_ROOT-prefixed EXT_BUILD_DEPS staging in $script" >&2
  exit 1
fi
