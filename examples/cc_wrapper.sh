#!/usr/bin/env bash

# This wrapper exists to provide a simplified way to wrap the compiler to do
# the simple examples (make/ninja) that don't have the capability of doing
# their own compiler setup. This exists _just_ to demonstrate and test
# functionality for these simple builds, and if you're doing something real,
# for your sake, use a full cross-platform build system like cmake and _don't_
# use this script :)

set -euo pipefail
set -x

die() {
    echo "$*" >&2
    exit 42
}

ensure_absolute() {
    case "$1" in
        /*|[A-Za-z]:/*)
            # already absolute (maybe with a drive path)
            echo "$1"
            ;;
        *)
            echo "$EXT_BUILD_ROOT/$1"
            ;;
    esac
}

compile() {
    if [[ -z "${CXX:-}" ]]; then
        die "CXX is not set"
    fi

    local cxx
    cxx="$(ensure_absolute "$CXX")"

    case "$cxx" in
        */cl.exe)
            "$cxx" /c "$1" ${CXXFLAGS:-} "/Fo$2"
            ;;
        *)
            "$cxx" -c "$1" ${CXXFLAGS:-} -o "$2"
            ;;
    esac
}

static_link() {
    if [[ -z "${AR:-}" ]]; then
        die "AR is not set"
    fi

    local ar
    ar="$(ensure_absolute "$AR")"

    case "$ar" in
        */lib.exe)
            "$ar" ${ARFLAGS:-} "/OUT:$2" "$1"
            ;;
        */libtool)
            # Note that this is darwin libtool, not gnu.
             "$ar" ${ARFLAGS:-} -static -o "$2" "$1"
             ;;
        *)
            "$ar" rcs ${ARFLAGS:-} "$2" "$1"
            ;;
    esac
}

if [[ -z "${EXT_BUILD_ROOT:-}" ]]; then
    die "EXT_BUILD_ROOT is not set"
fi

if [[ "$#" -ne 3 ]]; then
    echo "$0 <verb> <input> <output>"
fi

verb=$1
input=$2
output=$3

case "$verb" in
    compile) compile "$input" "$output" ;;
    static_link) static_link "$input" "$output" ;;
    *) die "unknown verb: $verb" ;;
esac
