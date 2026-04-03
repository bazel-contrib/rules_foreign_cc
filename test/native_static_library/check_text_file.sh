#!/usr/bin/env bash

set -euo pipefail

actual="$1"
expected="$2"

diff -u "$expected" "$actual"
