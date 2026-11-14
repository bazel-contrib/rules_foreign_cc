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
to add `CcToolchainInfo.static_runtime_lib` to C and C++ links. This includes
CMake compiler checks and places the runtime libraries after project objects
and libraries. The files are declared inputs to the foreign build action.
The default `none` preserves existing compiler-driver and user-supplied
runtime behavior; it does not mean the resulting links have no runtimes.

This covers the `cmake` rule and static runtime libraries only. Other foreign
build rules do not receive these libraries. Dynamic runtime libraries,
runfiles, and loader paths are not forwarded by this mechanism. Toolchains
with an empty static runtime set retain their existing CMake link behavior.
The end-to-end regression is qualified on Linux x86_64 with a GNU-style
Clang/LLD toolchain. Native Windows, macOS, and custom CMake toolchain files
have not been tested with toolchain-provided runtime archives.
