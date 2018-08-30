#!/usr/bin/env bash

if [ $1 == "true" ]; then
  NINJA_COMMAND="${TEST_SRCDIR}/rules_foreign_cc/external/foreign_cc_platform_utils/ninja/ninja"
else
  NINJA_COMMAND="ninja"
fi

echo "Ninja command: $NINJA_COMMAND"
NINJA_VERSION=$(${NINJA_COMMAND} --version)
echo "Version: $NINJA_VERSION"

if [ "x$NINJA_VERSION" != "x1.8.2" ]; then
  echo "Wrong ninja version: $NINJA_VERSION"
  exit -1
fi