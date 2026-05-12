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

runtime_paths() {
  case "$OSTYPE" in
    darwin*)
      otool -l "$1" |
        sed -n 's/^[[:space:]]*path \([^ ]*\) (offset [0-9]*)$/\1/p'
      ;;
    *)
      readelf -d "$1" |
        sed -n \
          -e 's/.*(RPATH).*Library rpath: \[\(.*\)\]/\1/p' \
          -e 's/.*(RUNPATH).*Library runpath: \[\(.*\)\]/\1/p' |
        tr ':' '\n'
      ;;
  esac
}

assert_path() {
  local file="$1"
  local expected="$2"
  local actual

  actual="$(runtime_paths "$file")"
  if ! grep -Fx "$expected" <<< "$actual" >/dev/null; then
    echo >&2 "missing runtime search path"
    echo >&2 "file: $file"
    echo >&2 "expected: $expected"
    echo >&2 "actual:"
    printf '%s\n' "$actual" >&2
    exit 1
  fi
}

assert_path_prefix() {
  local file="$1"
  local expected="$2"
  local actual
  local path

  actual="$(runtime_paths "$file")"
  while IFS= read -r path; do
    if [[ "$path" == "$expected"* ]]; then
      return
    fi
  done <<< "$actual"

  echo >&2 "missing runtime search path prefix"
  echo >&2 "file: $file"
  echo >&2 "expected prefix: $expected"
  echo >&2 "actual:"
  printf '%s\n' "$actual" >&2
  exit 1
}

case "$OSTYPE" in
  darwin*)
    app_runtime_path="@loader_path/../lib"
    middle_runtime_path="@loader_path/."
    solib_path="@loader_path/../../../../_solib_"
    solib_sibling_path="@loader_path/../_"
    ;;
  *)
    app_runtime_path='$ORIGIN/../lib'
    middle_runtime_path='$ORIGIN/.'
    solib_path='$ORIGIN/../../../../_solib_'
    solib_sibling_path='$ORIGIN/../_'
    ;;
esac

app_files=()
middle_files=()

for runfile in ${FILES:?FILES must be set}; do
  file="$(rlocation "$runfile")"
  if [[ -z "$file" || ! -f "$file" ]]; then
    continue
  fi

  case "$(basename "$runfile")" in
    runtime_app)
      app_files+=("$file")
      ;;
    libmiddle.so|libmiddle.dylib)
      middle_files+=("$file")
      ;;
  esac
done

if [[ "${#app_files[@]}" -eq 0 && "${#middle_files[@]}" -eq 0 ]]; then
  echo >&2 "FILES contains no runtime_app or libmiddle output"
  exit 1
fi

# macOS still ships Bash 3.2, where expanding an empty array under `set -u`
# fails even when the array was initialized.
if [[ "${#app_files[@]}" -gt 0 ]]; then
  for file in "${app_files[@]}"; do
    assert_path "$file" "$app_runtime_path"
  done
fi

if [[ "${#middle_files[@]}" -gt 0 ]]; then
  for file in "${middle_files[@]}"; do
    assert_path "$file" "$middle_runtime_path"
    if [[ "${#app_files[@]}" -eq 0 ]]; then
      assert_path_prefix "$file" "$solib_path"
      assert_path_prefix "$file" "$solib_sibling_path"
    fi
  done
fi
