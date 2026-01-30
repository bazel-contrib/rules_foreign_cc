#!/usr/bin/env bash

set -euo pipefail

ninja_jobs=${NINJA_JOBS:-0}

if [[ $ninja_jobs -gt 0 ]]; then
    exec "$EXT_BUILD_ROOT/$REAL_NINJA" "-j$ninja_jobs" "$@"
fi
exec "$EXT_BUILD_ROOT/$REAL_NINJA" "$@"
