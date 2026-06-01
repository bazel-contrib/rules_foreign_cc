# Foreign CC toolchain patches

## [cmake-c++11.patch](./cmake-c++11.patch)

See <https://discourse.cmake.org/t/cmake-error-at-cmakelists-txt-117-message-the-c-compiler-does-not-support-c-11-e-g-std-unique-ptr/3774/8>

## [make-reproducible-bootstrap.patch](./make-reproducible-bootstrap.patch)

Replaces the `LIBDIR`/`INCLUDEDIR`/`LOCALEDIR` strings baked into make 4.3
with the placeholder `nonexistent` so the bootstrapped binary does not
embed the absolute sandbox `--prefix` path. Without this patch, every
machine produces a different `bin/make` and downstream
`cc_cmake_make_rule` actions miss the remote cache. The embedded strings
are fallback search paths only (see `default_include_directories[]` in
`src/read.c`, the `LIBDIR` fallback in `src/remake.c`, and `LOCALEDIR`
passed to `bindtextdomain` in `src/main.c`); a relative path that won't
resolve to an existing directory keeps the strings inert at runtime
regardless of cwd.

## [make-4.4-reproducible-bootstrap.patch](./make-4.4-reproducible-bootstrap.patch)

Same fix as above, adapted to make 4.4. In 4.4 the `INCLUDEDIR` macro is
emitted via the `am__append_1` autoconf-conditional (set whenever
`--prefix` is not one of `/usr/local`, `/usr/gnu`, or `/usr`), so two
hunks are required.

## [make-4.4.1-reproducible-bootstrap.patch](./make-4.4.1-reproducible-bootstrap.patch)

Same fix as above, adapted to make 4.4.1.

## [pkgconfig-builtin-glib-int-conversion.patch](./pkgconfig-builtin-glib-int-conversion.patch)

This patch fixes explicit integer conversion which causes errors in `clang >= 15` and `gcc >= 14`

## [pkgconfig-detectenv.patch](./pkgconfig-detectenv.patch)

This patch is required as bazel does not provide the VCINSTALLDIR or WINDOWSSDKDIR vars

## [pkgconfig-makefile-vc.patch](./pkgconfig-makefile-vc.patch)

This patch is required as rules_foreign_cc runs in MSYS2 on Windows and MSYS2's "mkdir" is used
