# Transitive zlib/libarchive native/foreign matrix

This directory tests a real upstream C dependency graph:

```text
app binary -> libarchive -> zlib
```

Both zlib and libarchive are built from source. zlib targets are modeled after
`examples/third_party/zlib/BUILD.zlib.bazel`; libarchive has matching source
targets in `examples/third_party/libarchive/BUILD.libarchive.bazel`.

## Goals

- Confirm source-built zlib and libarchive can be substituted across native
  `cc_*` and foreign_cc producers.
- Confirm final binaries link and run correctly through the transitive
  `app -> libarchive -> zlib` path.
- Confirm produced binaries and shared libraries record the expected
  static-versus-shared dependency shape.
- Confirm shared-library runtime loading works without ambient
  `LD_LIBRARY_PATH` or `DYLD_LIBRARY_PATH` on Unix, and with only the expected
  Bazel output DLL directories on Windows.
- Confirm foreign_cc-produced `CcInfo` has semantic parity with comparable
  native `cc_*` provider targets after normalizing implementation-specific
  filenames and symlink shapes.

## Matrix and layout

The layout is divided into three sections:

1. `cc_*` and `cmake_*` directories contain the matrix runtime and linkage
   tests for every scenario involving the transitive path from `app` to `zlib`.
   There are 48 scenarios in total.
2. `provider_parity` contains `CcInfo` provider parity tests for zlib and
   libarchive producers.
3. `known_gap` contains tests for known gaps in foreign_cc that have not been
   remediated yet.

For the matrix tests, the package prefix identifies the app consumer:

| Package prefix | Role                 |
| -------------- | -------------------- |
| `cc_*`         | `cc_binary` consumer |
| `cmake_*`      | `cmake` consumer     |

The package suffix identifies how the app consumes libarchive:

| Package suffix | Role                                                                       |
| -------------- | -------------------------------------------------------------------------- |
| `*_static`     | app consuming a static libarchive producer through `deps`                  |
| `*_direct`     | app consuming a foreign shared libarchive producer directly through `deps` |
| `*_wrap`       | app consuming native shared libarchive through a `cc_library` wrapper      |
| `*_dynamic`    | app consuming native shared libarchive through `dynamic_deps`              |

Because Windows has long-path limits, leaf packages and targets use short IDs.
The context for each scenario is described in the individual `BUILD.bazel`
file. The leaf packages also prevent different targets in the same package from
producing conflicting DLLs, such as multiple differently linked `archive.dll`
files in one package output directory.

## Scenarios

The matrix suite implements 48 app build scenarios, with one runtime test and
one linkage test per scenario. The scenarios are enumerated from four zlib
producer shapes, four libarchive producer shapes, and the valid app link modes
for each libarchive output shape. Each libarchive producer shape is crossed
with the four zlib producer shapes, giving 16 libarchive producer targets.

### Producers

| Producer   | Shape           | Target family                                             |
| ---------- | --------------- | --------------------------------------------------------- |
| zlib       | static          | `@examples_zlib//:zlib_static`                            |
| zlib       | foreign static  | `@examples_zlib//:zlib_foreign_static`                    |
| zlib       | dynamic wrapper | `@examples_zlib//:zlib_dynamic`                           |
| zlib       | foreign shared  | `@examples_zlib//:zlib_foreign_shared`                    |
| libarchive | static          | `@examples_libarchive//:libarchive_static_zlib_*`         |
| libarchive | foreign static  | `@examples_libarchive//:libarchive_foreign_static_zlib_*` |
| libarchive | dynamic wrapper | `@examples_libarchive//:libarchive_dynamic_zlib_*`        |
| libarchive | foreign shared  | `@examples_libarchive//:libarchive_foreign_shared_zlib_*` |

See [BUILD.zlib.bazel](../../third_party/zlib/BUILD.zlib.bazel) and
[BUILD.libarchive.bazel](../../third_party/libarchive/BUILD.libarchive.bazel).

### Consumers

Each leaf package lists one explicit scenario-level macro call. The call site
shows the app producer, app link mode, `deps`, `dynamic_deps` where applicable,
`linkstatic` where applicable, and expected runtime-loaded libraries.

Except for `cmake_static`, the app-level consumer only links libarchive as a
direct dep; zlib enters transitively through the selected libarchive target.
`cmake_static` is the exception: those CMake app targets list zlib directly as
well, because CMake owns the final static link command. In the native
`cc_binary` static cases, Bazel traverses `CcInfo` from libarchive and adds the
required zlib archive to the final link line. A foreign_cc CMake app instead
receives staged libraries and link flags, then the upstream CMake project
decides what to pass to its `target_link_libraries`. A raw static libarchive
path does not carry a CMake transitive link interface for zlib, so these cases
name zlib explicitly to model a complete upstream static link.

| App package     | ID       | Consumer    | linkstatic | Link mode (libarchive)   | Link mode (zlib)      | BUILD file                                               |
| --------------- | -------- | ----------- | ---------- | ------------------------ | --------------------- | -------------------------------------------------------- |
| `cc_static`     | `s001`   | `cc_binary` | `True`     | native static            | native static         | [cc_static/s001](cc_static/s001/BUILD.bazel)             |
| `cc_static`     | `s002`   | `cc_binary` | `False`    | native static            | native static         | [cc_static/s002](cc_static/s002/BUILD.bazel)             |
| `cc_static`     | `s003`   | `cc_binary` | `True`     | native static            | foreign_cc static     | [cc_static/s003](cc_static/s003/BUILD.bazel)             |
| `cc_static`     | `s004`   | `cc_binary` | `False`    | native static            | foreign_cc static     | [cc_static/s004](cc_static/s004/BUILD.bazel)             |
| `cc_static`     | `s005`   | `cc_binary` | `True`     | native static            | native shared wrapper | [cc_static/s005](cc_static/s005/BUILD.bazel)             |
| `cc_static`     | `s006`   | `cc_binary` | `False`    | native static            | native shared wrapper | [cc_static/s006](cc_static/s006/BUILD.bazel)             |
| `cc_static`     | `s007`   | `cc_binary` | `True`     | native static            | foreign_cc shared     | [cc_static/s007](cc_static/s007/BUILD.bazel)             |
| `cc_static`     | `s008`   | `cc_binary` | `False`    | native static            | foreign_cc shared     | [cc_static/s008](cc_static/s008/BUILD.bazel)             |
| `cc_static`     | `s009`   | `cc_binary` | `True`     | foreign_cc static        | native static         | [cc_static/s009](cc_static/s009/BUILD.bazel)             |
| `cc_static`     | `s010`   | `cc_binary` | `False`    | foreign_cc static        | native static         | [cc_static/s010](cc_static/s010/BUILD.bazel)             |
| `cc_static`     | `s011`   | `cc_binary` | `True`     | foreign_cc static        | foreign_cc static     | [cc_static/s011](cc_static/s011/BUILD.bazel)             |
| `cc_static`     | `s012`   | `cc_binary` | `False`    | foreign_cc static        | foreign_cc static     | [cc_static/s012](cc_static/s012/BUILD.bazel)             |
| `cc_static`     | `s013`   | `cc_binary` | `True`     | foreign_cc static        | native shared wrapper | [cc_static/s013](cc_static/s013/BUILD.bazel)             |
| `cc_static`     | `s014`   | `cc_binary` | `False`    | foreign_cc static        | native shared wrapper | [cc_static/s014](cc_static/s014/BUILD.bazel)             |
| `cc_static`     | `s015`   | `cc_binary` | `True`     | foreign_cc static        | foreign_cc shared     | [cc_static/s015](cc_static/s015/BUILD.bazel)             |
| `cc_static`     | `s016`   | `cc_binary` | `False`    | foreign_cc static        | foreign_cc shared     | [cc_static/s016](cc_static/s016/BUILD.bazel)             |
| `cc_direct`     | `d001`   | `cc_binary` | `False`    | foreign_cc shared        | native static         | [cc_direct/d001](cc_direct/d001/BUILD.bazel)             |
| `cc_direct`     | `d002`   | `cc_binary` | `False`    | foreign_cc shared        | foreign_cc static     | [cc_direct/d002](cc_direct/d002/BUILD.bazel)             |
| `cc_direct`     | `d003`   | `cc_binary` | `False`    | foreign_cc shared        | native shared wrapper | [cc_direct/d003](cc_direct/d003/BUILD.bazel)             |
| `cc_direct`     | `d004`   | `cc_binary` | `False`    | foreign_cc shared        | foreign_cc shared     | [cc_direct/d004](cc_direct/d004/BUILD.bazel)             |
| `cc_dynamic`    | `dyn001` | `cc_binary` | `False`    | native cc_shared_library | native static         | [cc_dynamic/dyn001](cc_dynamic/dyn001/BUILD.bazel)       |
| `cc_dynamic`    | `dyn002` | `cc_binary` | `False`    | native cc_shared_library | foreign_cc static     | [cc_dynamic/dyn002](cc_dynamic/dyn002/BUILD.bazel)       |
| `cc_dynamic`    | `dyn003` | `cc_binary` | `False`    | native cc_shared_library | native shared wrapper | [cc_dynamic/dyn003](cc_dynamic/dyn003/BUILD.bazel)       |
| `cc_dynamic`    | `dyn004` | `cc_binary` | `False`    | native cc_shared_library | foreign_cc shared     | [cc_dynamic/dyn004](cc_dynamic/dyn004/BUILD.bazel)       |
| `cc_wrap`       | `w001`   | `cc_binary` | `False`    | native dynamic wrapper   | native static         | [cc_wrap/w001](cc_wrap/w001/BUILD.bazel)                 |
| `cc_wrap`       | `w002`   | `cc_binary` | `False`    | native dynamic wrapper   | foreign_cc static     | [cc_wrap/w002](cc_wrap/w002/BUILD.bazel)                 |
| `cc_wrap`       | `w003`   | `cc_binary` | `False`    | native dynamic wrapper   | native shared wrapper | [cc_wrap/w003](cc_wrap/w003/BUILD.bazel)                 |
| `cc_wrap`       | `w004`   | `cc_binary` | `False`    | native dynamic wrapper   | foreign_cc shared     | [cc_wrap/w004](cc_wrap/w004/BUILD.bazel)                 |
| `cmake_static`  | `s001`   | `cmake`     | `-`        | native static            | native static         | [cmake_static/s001](cmake_static/s001/BUILD.bazel)       |
| `cmake_static`  | `s002`   | `cmake`     | `-`        | native static            | foreign_cc static     | [cmake_static/s002](cmake_static/s002/BUILD.bazel)       |
| `cmake_static`  | `s003`   | `cmake`     | `-`        | native static            | native shared wrapper | [cmake_static/s003](cmake_static/s003/BUILD.bazel)       |
| `cmake_static`  | `s004`   | `cmake`     | `-`        | native static            | foreign_cc shared     | [cmake_static/s004](cmake_static/s004/BUILD.bazel)       |
| `cmake_static`  | `s005`   | `cmake`     | `-`        | foreign_cc static        | native static         | [cmake_static/s005](cmake_static/s005/BUILD.bazel)       |
| `cmake_static`  | `s006`   | `cmake`     | `-`        | foreign_cc static        | foreign_cc static     | [cmake_static/s006](cmake_static/s006/BUILD.bazel)       |
| `cmake_static`  | `s007`   | `cmake`     | `-`        | foreign_cc static        | native shared wrapper | [cmake_static/s007](cmake_static/s007/BUILD.bazel)       |
| `cmake_static`  | `s008`   | `cmake`     | `-`        | foreign_cc static        | foreign_cc shared     | [cmake_static/s008](cmake_static/s008/BUILD.bazel)       |
| `cmake_direct`  | `d001`   | `cmake`     | `-`        | foreign_cc shared        | native static         | [cmake_direct/d001](cmake_direct/d001/BUILD.bazel)       |
| `cmake_direct`  | `d002`   | `cmake`     | `-`        | foreign_cc shared        | foreign_cc static     | [cmake_direct/d002](cmake_direct/d002/BUILD.bazel)       |
| `cmake_direct`  | `d003`   | `cmake`     | `-`        | foreign_cc shared        | native shared wrapper | [cmake_direct/d003](cmake_direct/d003/BUILD.bazel)       |
| `cmake_direct`  | `d004`   | `cmake`     | `-`        | foreign_cc shared        | foreign_cc shared     | [cmake_direct/d004](cmake_direct/d004/BUILD.bazel)       |
| `cmake_dynamic` | `dyn001` | `cmake`     | `-`        | native cc_shared_library | native static         | [cmake_dynamic/dyn001](cmake_dynamic/dyn001/BUILD.bazel) |
| `cmake_dynamic` | `dyn002` | `cmake`     | `-`        | native cc_shared_library | foreign_cc static     | [cmake_dynamic/dyn002](cmake_dynamic/dyn002/BUILD.bazel) |
| `cmake_dynamic` | `dyn003` | `cmake`     | `-`        | native cc_shared_library | native shared wrapper | [cmake_dynamic/dyn003](cmake_dynamic/dyn003/BUILD.bazel) |
| `cmake_dynamic` | `dyn004` | `cmake`     | `-`        | native cc_shared_library | foreign_cc shared     | [cmake_dynamic/dyn004](cmake_dynamic/dyn004/BUILD.bazel) |
| `cmake_wrap`    | `w001`   | `cmake`     | `-`        | native dynamic wrapper   | native static         | [cmake_wrap/w001](cmake_wrap/w001/BUILD.bazel)           |
| `cmake_wrap`    | `w002`   | `cmake`     | `-`        | native dynamic wrapper   | foreign_cc static     | [cmake_wrap/w002](cmake_wrap/w002/BUILD.bazel)           |
| `cmake_wrap`    | `w003`   | `cmake`     | `-`        | native dynamic wrapper   | native shared wrapper | [cmake_wrap/w003](cmake_wrap/w003/BUILD.bazel)           |
| `cmake_wrap`    | `w004`   | `cmake`     | `-`        | native dynamic wrapper   | foreign_cc shared     | [cmake_wrap/w004](cmake_wrap/w004/BUILD.bazel)           |

## Tests

### Runtime assertion

Each `cc_*` and `cmake_*` consumer goes through a runtime test to make sure it
loads the expected libraries.

The consuming app uses libarchive's gzip filter to write a tar archive to
memory, then reads it back through libarchive. That forces libarchive to use
zlib rather than only linking it. Successful runs print exactly:

```text
expected libarchive+zlib loaded: payload=rules_foreign_cc_transitive_test
```

For shared-library cases, the app also reports the runtime loader path for
libarchive and zlib. The test compares those paths against the exact Bazel
runfiles for the expected shared-library targets, so a system library fallback
fails.

### Linkage assertion

Each scenario also runs a linkage test against the produced app and, when
libarchive is shared, the produced libarchive shared library. The test inspects
loader-visible dependency metadata and checks the expected link shape:

| Link shape                     | Expected metadata assertion                 |
| ------------------------------ | ------------------------------------------- |
| static libarchive, static zlib | app has no dynamic libarchive or zlib dep   |
| static libarchive, shared zlib | app has a dynamic zlib dep only             |
| shared libarchive, static zlib | app has libarchive; libarchive lacks zlib   |
| shared libarchive, shared zlib | app has libarchive; libarchive has zlib     |

On Linux this uses `readelf -d`, on macOS it uses `otool -L`, and on Windows it
uses `objdump -p`.

### Provider parity

The provider tests compare `CcInfo` from a foreign_cc target against a native
`cc_*` target that is intended to expose the same contract:

zlib targets are under `@examples_zlib//`:

| Foreign target         | Native comparison target | Platform              |
| ---------------------- | ------------------------ | --------------------- |
| `:zlib_foreign_static` | `:zlib_static`           | Linux, macOS, Windows |
| `:zlib_foreign_shared` | `:zlib_dynamic`          | Linux, macOS, Windows |

libarchive targets are under `@examples_libarchive//`:

| Foreign target                                   | Native comparison target                  | Platform              |
| ------------------------------------------------ | ----------------------------------------- | --------------------- |
| `:libarchive_foreign_static_zlib_static`         | `:libarchive_static_zlib_static`          | Linux, macOS, Windows |
| `:libarchive_foreign_static_zlib_foreign_static` | `:libarchive_static_zlib_foreign_static`  | Linux, macOS, Windows |
| `:libarchive_foreign_static_zlib_dynamic`        | `:libarchive_static_zlib_dynamic`         | Linux, macOS, Windows |
| `:libarchive_foreign_static_zlib_foreign_shared` | `:libarchive_static_zlib_foreign_shared`  | Linux, macOS, Windows |
| `:libarchive_foreign_shared_zlib_dynamic`        | `:libarchive_dynamic_zlib_dynamic`        | Linux, macOS, Windows |
| `:libarchive_foreign_shared_zlib_foreign_shared` | `:libarchive_dynamic_zlib_foreign_shared` | Linux, macOS, Windows |

The comparison projects `CcInfo` down to the parts that should be semantically
equivalent:

- compilation context: defines, local defines, whether headers are present, and
  whether include paths are present
- linking context: semantic static, dynamic, and interface link inputs; user
  link flags; and whether dynamic/interface libraries use Bazel solib symlinks
  with non-solib resolved files

Known fixture naming differences, version suffixes, import-library spelling
differences, and solib path prefixes are normalized because they are
representation details rather than provider contract differences. The
comparison intentionally does not assert static-vs-pic provider-slot identity.

## Additional scenarios

`known_gap_tests` keeps stricter cases that are expected to fail today. They are
tagged `manual`, disabled by default, and documented in `known_gap/README.md`.
Pass `--define=transitive_cc_foreign_known_gap=true` to reproduce them.

## Run

From `examples/`:

```bash
bazel test //integration_tests/transitive_matrix:tests --test_output=errors
bazel test //integration_tests/transitive_matrix/... --test_output=errors
bazel test //integration_tests/transitive_matrix:known_gap_tests \
  --define=transitive_cc_foreign_known_gap=true \
  --test_output=errors
```
