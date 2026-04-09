# Zlib Matrix

This directory has two separate goals:

1. show how `zlib` can be produced and consumed through both Bazel-native and
   foreign-build paths
2. validate how those producer and consumer shapes actually behave across
   Linux, macOS, and Windows

The current matrix is deliberately split into two layers:

- linkage tests inspect the produced binaries and check whether they link zlib
  statically or dynamically
- runnable tests exercise `runnable_binary` separately for a small shared
  slice, so runtime staging does not get mixed back into every linkage row
- on Linux and macOS, the runnable layer also checks the loader output so the
  test proves the staged zlib was loaded instead of a host copy
- on Windows, the runnable layer remains a smoke test for launch behavior only

## Shared Pieces

- Matrix helpers: [matrix_defs.bzl](./matrix_defs.bzl)
- Linkage verifier: [verify_zlib_linkage.sh](./verify_zlib_linkage.sh)
- Shared test source: [zlib-example.cpp](./zlib-example.cpp)
- Foreign CMake consumer source: [CMakeLists.txt](./CMakeLists.txt)
- Producer definitions: [BUILD.zlib.bazel](./BUILD.zlib.bazel)
- Root package and baseline test: [BUILD.bazel](./BUILD.bazel)

## Producers

- Foreign static producer: [zlib](./BUILD.zlib.bazel)
- Foreign shared producer: [zlib_foreign_shared](./BUILD.zlib.bazel)
- Native static producer: [zlib_native_static](./BUILD.zlib.bazel)
- Native shared producer: [zlib_native_shared](./BUILD.zlib.bazel)
- Native shared wrapped `cc_library`: [zlib_dynamic](./BUILD.zlib.bazel)
- Native shared headers-only compile surface:
  [zlib_dynamic_headers](./BUILD.zlib.bazel)

## Consumers

- Bazel native consumer pattern:
  [`cc_binary`](./native_static_cc_static/BUILD.bazel)
- Foreign consumer pattern:
  [`zlib_cmake_consumer`](./matrix_defs.bzl)

## Matrix

| Producer | Consumer | Link mode under test | Implementation |
| --- | --- | --- | --- |
| foreign static | `cc_binary(linkstatic=True)` | static | [foreign_static_cc_static](./foreign_static_cc_static/BUILD.bazel) |
| foreign static | `cc_binary(linkstatic=False)` | static | [foreign_static_cc_dynamic](./foreign_static_cc_dynamic/BUILD.bazel) |
| foreign shared | `cc_binary(linkstatic=False)` | dynamic | [foreign_shared_cc_dynamic](./foreign_shared_cc_dynamic/BUILD.bazel) |
| foreign static | `cmake()` | static | [foreign_static_cmake](./foreign_static_cmake/BUILD.bazel) |
| foreign shared | `cmake()` | dynamic | [foreign_shared_cmake](./foreign_shared_cmake/BUILD.bazel) |
| native static | `cc_binary(linkstatic=True)` | static | [native_static_cc_static](./native_static_cc_static/BUILD.bazel) |
| native static | `cc_binary(linkstatic=False)` | static | [native_static_cc_dynamic](./native_static_cc_dynamic/BUILD.bazel) |
| native shared | `cc_binary(linkstatic=False)` via wrapped `cc_library` | dynamic | [native_shared_cc_wrapped](./native_shared_cc_wrapped/BUILD.bazel) |
| native shared | `cc_binary(linkstatic=False)` via `dynamic_deps` | dynamic | [native_shared_cc_dynamic_deps](./native_shared_cc_dynamic_deps/BUILD.bazel) |
| native static | `cmake()` | static | [native_static_cmake](./native_static_cmake/BUILD.bazel) |
| native shared | `cmake()` via wrapped `cc_library` | dynamic | [native_shared_cmake_wrapped](./native_shared_cmake_wrapped/BUILD.bazel) |
| native shared | `cmake()` via `dynamic_deps` | dynamic | [native_shared_cmake_dynamic_deps](./native_shared_cmake_dynamic_deps/BUILD.bazel) |

## What The Matrix Is Testing

Each row is trying to answer one specific question:

- Can a Bazel-native consumer link the producer the way the target shape
  suggests it should?
- Can a foreign CMake consumer rediscover and link the staged dependency tree
  the same way?
- Do `deps` and `dynamic_deps` behave the same way, or do they surface
  different shared-library contracts?

The linkage matrix does not try to answer whether a produced binary can always
be run directly from a `sh_test` on Windows. That behavior depends on Bazel's
own Windows DLL/runtime handling and is separate from basic
`rules_foreign_cc` linkage behavior.

## Related Coverage

The root package still keeps one simple non-matrix baseline:

- Bazel baseline consumer: [zlib_usage_example](./BUILD.bazel)
- Baseline static linkage test: [test_zlib](./BUILD.bazel)
- Runnable shared foreign CMake coverage:
  [foreign_shared_cmake:app_run_test](./foreign_shared_cmake/BUILD.bazel)
- Runnable native shared CMake coverage through `dynamic_deps`:
  [native_shared_cmake_dynamic_deps:app_run_test](./native_shared_cmake_dynamic_deps/BUILD.bazel)

Those runnable rows are intentionally small. They are there to validate
`runnable_binary` runtime staging without turning every matrix row into a
runtime test. On Linux and macOS they also assert that the loaded zlib path
comes from the staged test inputs rather than the host runtime. For the native
shared row, that staged path comes from the Bazel-produced `examples_zlib`
library tree across both workspace and bzlmod layouts.
