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

## Ninja runtime libraries

Set `--@rules_foreign_cc//foreign_cc/settings:ninja_cc_runtime_libraries=static`
or `=dynamic` on the direct `ninja` rule to select `CcToolchainInfo.static_runtime_lib`
or `dynamic_runtime_lib`, respectively. The selected files are declared build
inputs. The default `none` and empty selected sets preserve existing behavior.

The project controls its Ninja link commands. For a POSIX shell and a compiler
driver that accepts `@file`, place the response file after the project objects
and libraries. For example, use this link rule with the project libraries in
`$in`.

```ninja
rule link
  command = "$$CXX" $$LDFLAGS -o $out $in $${RFCC_CC_RUNTIME_RESPONSE_FILE:+@"$$RFCC_CC_RUNTIME_RESPONSE_FILE"}
```

The `$$` escapes pass shell variable references through Ninja. The response
file contains absolute library paths in toolchain order. Manifests that omit
the expansion keep their own link commands.

With `dynamic`, rfcc also adds the runtime files to the target's runfiles and
exports `RFCC_CC_RUNTIME_LIBRARY_DIRS`. The directories are separated by `:`
on Unix and `;` for Windows targets. A native Linux build-time probe can
set its loader path for the probe command.

```ninja
rule probe
  command = LD_LIBRARY_PATH="$${RFCC_CC_RUNTIME_LIBRARY_DIRS:+$$RFCC_CC_RUNTIME_LIBRARY_DIRS$${LD_LIBRARY_PATH:+:}}$$LD_LIBRARY_PATH" ./$in
```

Use `runnable_binary` or the project's own loader configuration for installed
executables. The link and loader examples were tested on Linux x86_64 with
Clang and LLD. Native Windows and macOS runtime linking and loading remain
unverified. CMake projects using the Ninja generator use the CMake setting.
