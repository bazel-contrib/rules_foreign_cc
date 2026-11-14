# Rules

- [cmake](./cmake.md)
- [configure_make](./configure_make.md)
- [make](./make.md)
- [meson](./meson.md)
- [ninja](./ninja.md)

For additional rules/macros/providers, see the [full API in one page](./flatten.md).

## CMake runtime libraries

When the selected C++ toolchain provides static runtime libraries through
`CcToolchainInfo.static_runtime_lib`, the `cmake` rule passes them to C and C++
links automatically. This includes CMake compiler checks and places the runtime
libraries after project objects and libraries. The files are declared inputs
to the foreign build action; no opt-in attribute is needed.

This covers the `cmake` rule and static runtime libraries only. Other foreign
build rules do not receive these libraries. Dynamic runtime libraries,
runfiles, and loader paths are not forwarded by this mechanism. Toolchains
with an empty static runtime set retain their existing CMake link behavior.
The end-to-end regression is qualified on Linux x86_64 with a GNU-style
Clang/LLD toolchain. Native Windows, macOS, and custom CMake toolchain files
have not been tested with toolchain-provided runtime archives.
