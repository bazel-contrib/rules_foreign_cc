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

This setting applies to the `cmake` rule. An empty selected runtime set retains
the existing CMake link behavior. The end-to-end regressions are qualified on
Linux x86_64 with a GNU-style Clang/LLD toolchain. Native Windows, macOS, and
custom CMake toolchain files have not been tested with toolchain-provided
runtime files.

## Configure and Make runtime libraries

Set `--@rules_foreign_cc//foreign_cc/settings:configure_make_cc_runtime_libraries=static`
or `=dynamic` to add the complete `CcToolchainInfo.static_runtime_lib` or
`dynamic_runtime_lib` set to a `configure_make` build. The default `none`
preserves the existing behavior. The selected files are declared inputs to the
foreign build action.

The adapter appends the runtime files to the existing `LIBS` in the configure
environment. Autoconf uses it for link probes and Automake substitutes it into
the Makefile for final links. Custom configure scripts and Makefiles must
carry that value through and use it after project objects and libraries.
The compiler driver must accept the selected runtime files as link inputs.
Any `LIBS=...` override in `configure_options` or make `args` can replace
the runtime libraries and other libraries collected by configure.

`dynamic` includes the selected files in the target's runfiles. When the
execution and target platforms are both Linux and use the same CPU architecture,
the adapter also prepends their directories to `LD_LIBRARY_PATH` for configure
and make. Use `runnable_binary` to run an installed binary within Bazel.
This feature was tested on Linux x86_64 with Autoconf, Automake, and Clang/LLD.

## Make runtime libraries

To pass the C++ toolchain's complete static or dynamic runtime file set to a
direct `make` build, set
`--@rules_foreign_cc//foreign_cc/settings:make_cc_runtime_libraries=static`
or `=dynamic`. The selected files are build action inputs. The default `none`
and empty runtime file sets preserve the existing Make invocation.

The Makefile must expand `$(RULES_FOREIGN_CC_RUNTIME_LIBS)` after all objects
and project libraries in each link recipe that needs the runtimes. The
variable contains shell-quoted paths to the selected files in toolchain
order. GNU Make passes the command-line variable to recursive `$(MAKE)`
invocations.

```make
app: main.o libproject.a
	$(CXX) $(LDFLAGS) $^ $(LDLIBS) $(RULES_FOREIGN_CC_RUNTIME_LIBS) -o $@
```

When `dynamic` selects files, `RULES_FOREIGN_CC_RUNTIME_LIBRARY_PATH`
contains their colon-separated directories in the build action. A native
Linux probe can use this variable to set its loader path for its own invocation.

```make
check: app
	$(if $(RULES_FOREIGN_CC_RUNTIME_LIBRARY_PATH),LD_LIBRARY_PATH="$(RULES_FOREIGN_CC_RUNTIME_LIBRARY_PATH)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}") ./app
```

For installed executables, use `runnable_binary` to load the dynamic runtimes
from the foreign target's runfiles, or arrange a loader path when packaging
the executable. The Makefile controls execution of build-time probes and must
account for the target platform when cross-compiling.

The selected files must be valid inputs for the recipe's linker. Both modes
were tested with GNU Make and Clang/LLD on Linux x86_64.

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
