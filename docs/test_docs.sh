#!/bin/bash

set -euo pipefail

pushd "${BUILD_WORKSPACE_DIRECTORY}" &> /dev/null
bazel run //:generate_docs
if [ -n "$(git status --porcelain)" ]; then 
    git status
    echo '/docs is out of date. Please run `bazel run //:generate_docs` from that directory and commit the results' >&2
    exit 1
fi
popd &> /dev/null
