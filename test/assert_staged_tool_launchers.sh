#!/usr/bin/env bash
set -euo pipefail

runfiles_root="${RUNFILES_DIR:-${TEST_SRCDIR:-}}"
workspace_root="${runfiles_root}/${TEST_WORKSPACE}"

meson="${workspace_root}/toolchains/private/meson_tool"
ninja_wrapper="${workspace_root}/toolchains/private/out/ninja"
ninja_tree="${workspace_root}/toolchains/private/ninja"

if [[ ! -e "$meson" && -e "${meson}.exe" ]]; then
  meson="${meson}.exe"
fi

if [[ ! -e "$ninja_wrapper" && -e "${ninja_wrapper}.exe" ]]; then
  ninja_wrapper="${ninja_wrapper}.exe"
fi

if [[ ! -e "$meson" || ! -e "$ninja_wrapper" || ! -d "$ninja_tree" ]]; then
  echo "missing expected tool paths in runfiles" >&2
  printf 'meson=%q\nninja_wrapper=%q\nninja_tree=%q\n' \
    "$meson" "$ninja_wrapper" "$ninja_tree" >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/bin" "$tmpdir/work"

cp -f "$meson" "$tmpdir/bin/$(basename "$meson")"
"$tmpdir/bin/$(basename "$meson")" --version >/dev/null

ninja_bin="$ninja_tree/bin/ninja"
if [[ -x "$ninja_tree/bin/ninja.exe" ]]; then
  ninja_bin="$ninja_tree/bin/ninja.exe"
fi

cp -f "$ninja_wrapper" "$tmpdir/bin/$(basename "$ninja_wrapper")"
(
  cd "$tmpdir/work"
  EXT_BUILD_ROOT="$tmpdir/work" REAL_NINJA="$ninja_bin" \
    "$tmpdir/bin/$(basename "$ninja_wrapper")" --version >/dev/null
)
