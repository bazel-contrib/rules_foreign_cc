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
