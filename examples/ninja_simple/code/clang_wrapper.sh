#!/bin/bash -eu

if [[ $(uname) == *"NT"* ]]; then
 # If Windows
  exec clang-cl "$@"
else
  exec clang "$@"
fi
