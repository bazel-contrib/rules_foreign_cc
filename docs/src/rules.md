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

The CMake setting applies to `cmake` targets. An empty selected runtime set
retains the existing CMake link behavior. The regressions were run on Linux
x86_64 with a GNU-style Clang/LLD toolchain. Native Windows, macOS, and custom
CMake toolchain files have not been tested with toolchain-provided runtime files.

## Boost.Build runtime libraries

Set `--@rules_foreign_cc//foreign_cc/settings:boost_build_cc_runtime_libraries=static`
or `=dynamic` to add the corresponding C++ toolchain runtime file set to
`boost_build` links. The default `none` and empty runtime sets retain existing
behavior. The selected libraries are declared action inputs. B2's GCC and
Clang toolsets place these libraries after project objects and dependencies
in executable and shared-library links, including B2 configuration checks.
`bootstrap.sh` builds B2 separately.

Runtime injection requires Linux execution and target platforms and the rule's
generated GCC or Clang configuration. With `dynamic`, rfcc also adds the files
to runfiles and their directories to the loader path for the B2 invocation.
Use `runnable_binary` for installed executables or provide a loader path when
running them outside Bazel.
