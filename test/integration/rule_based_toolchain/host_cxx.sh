#!/usr/bin/env bash
# Host c++, wrapped so a rule-based cc_tool can point at a checked-in file.
exec c++ "$@"
