#!/usr/bin/env bash
# Host cc, wrapped so a rule-based cc_tool can point at a checked-in file.
exec cc "$@"
