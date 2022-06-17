#!/usr/bin/env bash

set -euo pipefail

echo STABLE_SCM_SHORT_VERSION "$(git rev-parse --short HEAD)"
echo STABLE_SCM_VERSION "$(git rev-parse HEAD)"
echo STABLE_RELEASE "$(cat ../version.bzl | grep VERSION | sed 's/VERSION = "//' | sed 's/"//')"
