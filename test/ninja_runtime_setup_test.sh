#!/usr/bin/env bash
set -euo pipefail

export EXT_BUILD_ROOT="$TEST_TMPDIR/exec root"
export EXT_BUILD_DEPS="$TEST_TMPDIR/foreign deps"
mkdir -p "$EXT_BUILD_DEPS"

# shellcheck disable=SC1090
source "$1"

test "$RFCC_CC_RUNTIME_LIBRARY_DIRS" = "$EXT_BUILD_ROOT/z first:$EXT_BUILD_ROOT/a second"
diff -u - "$RFCC_CC_RUNTIME_RESPONSE_FILE" <<EOF
"$EXT_BUILD_ROOT/z first/lib\"first\$\$.so"
"$EXT_BUILD_ROOT/a second/libsecond.so"
EOF
