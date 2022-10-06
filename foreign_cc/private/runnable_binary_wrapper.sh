#!/usr/bin/env bash

# --- begin runfiles.bash initialization v2 ---
# Copy-pasted from the Bazel Bash runfiles library v2. (@bazel_tools//tools/bash/runfiles)
set -uo pipefail; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
source "$0.runfiles/$f" 2>/dev/null || \
source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
{ echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v2 ---

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    SHARED_LIB_SUFFIX=".so*"
    LIB_PATH_VAR=LD_LIBRARY_PATH
elif [[ "$OSTYPE" == "darwin"* ]]; then
    SHARED_LIB_SUFFIX=".dylib"
    LIB_PATH_VAR=DYLD_LIBRARY_PATH
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    SHARED_LIB_SUFFIX=".dll"
    LIB_PATH_VAR=PATH
fi

# Add paths to shared libraries to SHARED_LIBS_ARRAY
SHARED_LIBS_ARRAY=()
while IFS=  read -r -d $'\0'; do
    SHARED_LIBS_ARRAY+=("$REPLY")
done < <(find . -name "*${SHARED_LIB_SUFFIX}" -print0)

# Add paths to shared library directories to SHARED_LIBS_DIRS_ARRAY
SHARED_LIBS_DIRS_ARRAY=()
for lib in "${SHARED_LIBS_ARRAY[@]}"; do
    SHARED_LIBS_DIRS_ARRAY+=($(dirname $(realpath $lib)))
done

# Remove duplicates from array
IFS=" " read -r -a SHARED_LIBS_DIRS_ARRAY <<< "$(tr ' ' '\n' <<< "${SHARED_LIBS_DIRS_ARRAY[@]}" | sort -u | tr '\n' ' ')"

# Allow unbound variable here, in case LD_LIBRARY_PATH or similar is not already set
set +u
for dir in "${SHARED_LIBS_DIRS_ARRAY[@]}"; do
    export ${LIB_PATH_VAR}="${!LIB_PATH_VAR}":"$dir"
done
set -u

EXE=BIN
$(rlocation "${EXE#external/}") $@