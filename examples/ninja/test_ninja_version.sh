#!/usr/bin/env bash

NINJA_VERSION=$(${TEST_SRCDIR}/rules_foreign_cc/examples/ninja/ninja/ninja --version)
echo "Version: $NINJA_VERSION"

if [ "x$NINJA_VERSION" != "x1.8.2" ]; then
  echo "Wrong ninja version: $NINJA_VERSION"
  exit -1
fi