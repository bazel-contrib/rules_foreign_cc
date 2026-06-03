# Runtime library search directories

This package tests that foreign_cc can add runtime loader search paths for
libraries produced by other foreign_cc targets and for libraries produced by the
same foreign_cc target.

The tests are intentionally small. They do not try to cover every possible
native or foreign_cc provider shape; that broader matrix lives in
`examples/integration_tests/transitive_matrix`. This package focuses on whether
the exported `cmake`, `make`, `configure_make`, `meson`, and `ninja` rules pass
the right linker flags to the upstream build system when
`runtime_library_search_directories = "enabled"` is set.

On Linux, the resulting binary and shared libraries use ELF `RUNPATH` or
`RPATH`. On macOS, they use rpath install names.

## Runtime chain

All rule families build the same small C dependency chain:

```text
runtime_app -> libmiddle -> libleaf
```

`libleaf` returns a fixed marker string. `libmiddle` calls `libleaf` and prefixes
the marker with the rule family. `runtime_app` calls `libmiddle`, prints the
result, and fails if the result does not match the expected value.

For example, the CMake dependency-chain test expects:

```text
cmake: expected libmiddle loaded through rpath -> expected libleaf loaded through rpath
```

The runtime test runner clears `LD_LIBRARY_PATH` and `DYLD_LIBRARY_PATH` before
running the binary. A separate runpath test runner inspects the produced binary
and shared libraries so a fallback runtime path cannot hide a missing expected
entry.

## Test shapes

Each supported rule family has two test shapes.

| Test shape       | Example target           | What it proves                                                                                                                            |
| ---------------- | ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Dependency chain | `cmake_test`             | A foreign_cc binary target can find a shared library from its direct dependency, and that shared library can find a shared library from its own dependency. |
| App bundle       | `cmake_app_bundle_test`  | A single foreign_cc target that produces both `bin/runtime_app` and libraries under `lib/` can make those outputs find each other.         |

The same shapes are repeated for:

| Rule family      | Dependency-chain test   | App-bundle test                    |
| ---------------- | ----------------------- | ---------------------------------- |
| `cmake`          | `cmake_test`            | `cmake_app_bundle_test`            |
| `make`           | `make_test`             | `make_app_bundle_test`             |
| `configure_make` | `configure_make_test`   | `configure_make_app_bundle_test`   |
| `meson`          | `meson_test`            | `meson_app_bundle_test`            |
| `ninja`          | `ninja_test`            | `ninja_app_bundle_test`            |

## Dependency-chain tests

The dependency-chain tests build each component as a separate foreign_cc target:

```text
<family>_leaf   -> installs libleaf under lib/
<family>_middle -> installs libmiddle under lib/, depends on <family>_leaf
<family>_app    -> installs runtime_app under bin/, depends on <family>_middle
```

The important behavior is that runtime search directories are derived from the
foreign_cc dependency graph:

- `runtime_app` needs a runtime search path to find `libmiddle`.
- `libmiddle` needs a runtime search path to find `libleaf`.
- The test binary must run without `LD_LIBRARY_PATH` or `DYLD_LIBRARY_PATH`.
- The middle shared library must record self, install-tree-to-solib, and solib
  sibling runtime search paths.

## App-bundle tests

The app-bundle tests build `runtime_app`, `libmiddle`, and `libleaf` from one
foreign_cc target:

```text
<family>_app_bundle -> installs runtime_app under bin/
                     -> installs libmiddle and libleaf under lib/
```

These tests verify the same-target app bundle behavior:

- a binary installed under `bin/` can find libraries installed under `lib/`
- a shared library installed under `lib/` can find sibling libraries in `lib/`
- the app and middle shared library record the expected same-install-tree
  runtime search paths.

This is useful for upstream projects that produce an executable and companion
shared libraries in the same install tree, but do not set their own relative
runtime search paths.

## Fixture files

| File                           | Purpose                                                                                                                                    |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `CMakeLists.txt`               | Builds the chain for the `cmake` rule.                                                                                                     |
| `Makefile`                     | Builds the chain directly for the `make` rule.                                                                                             |
| `configure` and `Makefile.in`  | Provide a minimal configure-style wrapper for the `configure_make` rule.                                                                   |
| `runtime_chain_rules.mk`       | Shared Makefile logic used by `make` and `configure_make`.                                                                                 |
| `src/`                         | C sources for `runtime_app`, `libmiddle`, and `libleaf`.                                                                                   |
| `runtime_search_paths_test.sh` | Shared shell test runner that checks recorded runtime search paths on produced binaries and shared libraries.                              |
| `runtime_search_test.sh`       | Shared shell test runner that resolves the Bazel runfile binary, clears ambient library search variables, and checks the printed marker.   |

## Run

Run this package from the examples module:

```bash
cd examples
bazel test //integration_tests/runtime_library_search_directories:tests --test_output=errors
```
