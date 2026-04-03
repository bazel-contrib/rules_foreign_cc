#!/usr/bin/env bash

# shellcheck disable=SC1090

if [[ "$0" != /* ]]; then
    exec "$PWD/$0" "$@"
fi

WRAPPER_PATH="$0"
RUNFILES_MANIFEST=""

if [[ -n "${RUNFILES_DIR:-}" && -d "${RUNFILES_DIR}" ]]; then
    :
elif [[ -d "$WRAPPER_PATH.runfiles" ]]; then
    RUNFILES_DIR="$WRAPPER_PATH.runfiles"
elif [[ -d "$WRAPPER_PATH.exe.runfiles" ]]; then
    RUNFILES_DIR="$WRAPPER_PATH.exe.runfiles"
elif [[ -f "${RUNFILES_MANIFEST_FILE:-}" ]]; then
    RUNFILES_MANIFEST="$RUNFILES_MANIFEST_FILE"
elif [[ -f "$WRAPPER_PATH.runfiles_manifest" ]]; then
    RUNFILES_MANIFEST="$WRAPPER_PATH.runfiles_manifest"
elif [[ -f "$WRAPPER_PATH.exe.runfiles_manifest" ]]; then
    RUNFILES_MANIFEST="$WRAPPER_PATH.exe.runfiles_manifest"
else
    >&2 echo "ERROR: cannot find Bazel runfiles for ${WRAPPER_PATH}"
    exit 1
fi

if [[ -n "${RUNFILES_DIR:-}" && ! -d "${RUNFILES_DIR}" ]]; then
    >&2 echo "RUNFILES_DIR is set to '${RUNFILES_DIR:-}' which does not exist"
    exit 1
fi

if [[ -n "${RUNFILES_DIR:-}" ]]; then
    RUNFILES_DIR=$(cd "${RUNFILES_DIR}" || exit ; pwd -P)
fi

resolve_manifest_runfile() {
    local logical_path="$1"
    local manifest_line

    manifest_line=$(grep -sm1 "^${logical_path} " "${RUNFILES_MANIFEST}")
    if [[ -z "${manifest_line}" ]]; then
        return 1
    fi

    printf '%s\n' "${manifest_line#* }"
}

EXE=EXECUTABLE
if [[ -n "${RUNFILES_DIR:-}" && -e "${RUNFILES_DIR}/${EXE}" ]]; then
    EXE_PATH="${RUNFILES_DIR}/${EXE}"
else
    EXE_PATH=$(resolve_manifest_runfile "${EXE}")
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    SHARED_LIB_REGEX='\.so(\..*)?$'
    SHARED_LIB_FIND_ARGS=(-name '*.so' -o -name '*.so.*')
    LIB_PATH_VAR=LD_LIBRARY_PATH
elif [[ "$OSTYPE" == "darwin"* ]]; then
    SHARED_LIB_REGEX='\.dylib$'
    SHARED_LIB_FIND_ARGS=(-name '*.dylib')
    LIB_PATH_VAR=DYLD_LIBRARY_PATH
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    SHARED_LIB_REGEX='\.dll$'
    SHARED_LIB_FIND_ARGS=(-name '*.dll')
    LIB_PATH_VAR=PATH
fi

# Add paths to shared libraries to SHARED_LIBS_ARRAY
SHARED_LIBS_ARRAY=()
if [[ -n "${RUNFILES_DIR:-}" ]]; then
    while IFS=  read -r -d $'\0'; do
        SHARED_LIBS_ARRAY+=("$REPLY")
    done < <(find "${RUNFILES_DIR}" \( "${SHARED_LIB_FIND_ARGS[@]}" \) -print0)
elif [[ -n "${RUNFILES_MANIFEST}" ]]; then
    while IFS= read -r manifest_line; do
        SHARED_LIBS_ARRAY+=("${manifest_line#* }")
    done < <(grep -E " ${SHARED_LIB_REGEX}" "${RUNFILES_MANIFEST}")
fi

# Add paths to shared library directories to SHARED_LIBS_DIRS_ARRAY
SHARED_LIBS_DIRS_ARRAY=()
if [ ${#SHARED_LIBS_ARRAY[@]} -ne 0 ]; then
    for lib in "${SHARED_LIBS_ARRAY[@]}"; do
        SHARED_LIBS_DIRS_ARRAY+=("$(dirname "$(realpath "$lib")")")
    done
fi

if [ ${#SHARED_LIBS_DIRS_ARRAY[@]} -ne 0 ]; then
    # Remove duplicates from array
    IFS=" " read -r -a SHARED_LIBS_DIRS_ARRAY <<< "$(tr ' ' '\n' <<< "${SHARED_LIBS_DIRS_ARRAY[@]}" | sort -u | tr '\n' ' ')"

    # Allow unbound variable here, in case LD_LIBRARY_PATH or similar is not already set
    set +u
    for dir in "${SHARED_LIBS_DIRS_ARRAY[@]}"; do
        export "${LIB_PATH_VAR}"="${dir}:${!LIB_PATH_VAR}"
    done
    set -u
fi

exec "${EXE_PATH}" "$@"
