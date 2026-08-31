#!/usr/bin/env bash
set -euo pipefail

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

grep -F 'function validate_expected_output() {' "$script"
grep -F 'rules_foreign_cc: validating expected installed outputs' "$script"
grep -F 'rules_foreign_cc: other files in the same directory (max 5):' "$script"
grep -F 'rules_foreign_cc: other files in the install root with the same name (max 5):' "$script"
grep -F "find_bin=\"\${REAL_FIND:-find}\"" "$script"
