# Rules

- [cmake](./cmake.md)
- [configure_make](./configure_make.md)
- [make](./make.md)
- [meson](./meson.md)
- [ninja](./ninja.md)

For additional rules/macros/providers, see the [full API in one page](./flatten.md).

## CMake runtime libraries

By default, `cmake` does not add libraries from the C++ toolchain's runtime
file sets. Set
`--@rules_foreign_cc//foreign_cc/settings:cmake_cc_runtime_libraries=static`
or `=dynamic` to select the complete `CcToolchainInfo.static_runtime_lib` or
`dynamic_runtime_lib` set, respectively. This includes CMake compiler checks
and places the runtime libraries after project objects and libraries. The
selected files are declared inputs to the foreign build action.
The default `none` preserves existing compiler-driver and user-supplied
runtime behavior; it does not mean the resulting links have no runtimes.

With `dynamic`, rfcc also puts the selected runtime files in the foreign
target's runfiles and adds their directories to CMake's **build** RPATH so
native `try_run` checks can execute. This does not add an RPATH to installed
outputs. Run foreign-built executables with `runnable_binary`, as for other
shared-library dependencies, or arrange a project-specific loader path.

This covers the `cmake` rule only; other foreign build rules do not receive
these libraries. An empty selected runtime set retains the existing CMake link
behavior. The end-to-end regressions are qualified on Linux x86_64 with a
GNU-style Clang/LLD toolchain. Native Windows, macOS, and custom CMake
toolchain files have not been tested with toolchain-provided runtime files.

## Meson runtime libraries

Set `--@rules_foreign_cc//foreign_cc/settings:meson_cc_runtime_libraries=static`
or `=dynamic` on native Linux builds using GNU-style Clang 20 or newer with
`compiler = "clang"` in the Bazel C++ toolchain. The default `none` preserves
the existing build. An empty
selected runtime set also leaves the build unchanged.

Meson declares the complete selected `CcToolchainInfo.static_runtime_lib` or
`dynamic_runtime_lib` set as action inputs. Both C and C++ compiler commands
use a native file entry with a [Clang configuration file](https://clang.llvm.org/docs/UsersManual.html#configuration-files)
that adds those libraries after the project objects and libraries. It applies
to compiler link checks and target links. The generated native file takes
precedence over `c` and `cpp` entries in user native files. Meson cross files
are unsupported with a nonempty runtime set.

In dynamic mode, the action prepends the selected libraries' directories to
`LD_LIBRARY_PATH` for Meson and its child processes, including native compiler
probes that execute. The foreign target includes the shared runtimes in its
runfiles. Use `runnable_binary` or supply a loader search path when running
installed executables. The adapter adds no installed RPATH.
