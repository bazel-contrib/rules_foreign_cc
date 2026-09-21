#!/usr/bin/env bash

set -euo pipefail

# Meson rewrites Darwin install names and load commands during `meson install`
# from @rpath references to full absolute paths under Bazel's sandbox install
# directory. This fixture repairs Meson's installed outputs back to @rpath names
# so the test stays focused on foreign_cc runtime search paths.
[[ "$(uname -s)" == "Darwin" ]] || exit 0

libdir="${MESON_INSTALL_DESTDIR_PREFIX}/lib"
bindir="${MESON_INSTALL_DESTDIR_PREFIX}/bin"

if [[ -f "$libdir/libleaf.dylib" ]]; then
  install_name_tool -id @rpath/libleaf.dylib "$libdir/libleaf.dylib"
fi

if [[ -f "$libdir/libmiddle.dylib" ]]; then
  install_name_tool -id @rpath/libmiddle.dylib "$libdir/libmiddle.dylib"

  leaf_ref="$(otool -L "$libdir/libmiddle.dylib" | awk '/libleaf[.]dylib/ { print $1; exit }')"
  if [[ -n "$leaf_ref" && "$leaf_ref" != "@rpath/libleaf.dylib" ]]; then
    install_name_tool -change "$leaf_ref" @rpath/libleaf.dylib "$libdir/libmiddle.dylib"
  fi
fi

if [[ -f "$bindir/runtime_app" ]]; then
  middle_ref="$(otool -L "$bindir/runtime_app" | awk '/libmiddle[.]dylib/ { print $1; exit }')"
  if [[ -n "$middle_ref" && "$middle_ref" != "@rpath/libmiddle.dylib" ]]; then
    install_name_tool -change "$middle_ref" @rpath/libmiddle.dylib "$bindir/runtime_app"
  fi
fi
