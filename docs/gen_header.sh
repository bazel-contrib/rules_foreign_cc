#!/usr/bin/env bash

set -euo pipefail



# The block below functions as follows
#
# - Look for all assignments
# - Remove all load statements
# - Remove multi line load statements
# - Remvoe all whitespace
# - Remove all comments
# - Strip assignments
# - Generate `- [symbol](#sybol)` formatting
# - Sort entries
TABLE_OF_CONTENTS=$(grep "=" "$1" \
| sed '/^load.*/d' \
| sed '/,$/d' \
| sed '/^$/d' \
| sed '/^#/d' \
| sed 's/ = .*//' \
| python -c 'import sys; print("\n".join(["- [{}](#{})".format(symbol.strip(), symbol.strip().lower()) for symbol in sys.stdin.readlines()]))' \
| sort -f
)

cat << EOF > "$2"
<!-- Generated with Stardoc, Do Not Edit! -->
# Rules Foreign CC

${TABLE_OF_CONTENTS}
EOF
