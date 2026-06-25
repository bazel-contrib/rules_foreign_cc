# bzlmod examples

Copy-pasteable `MODULE.bazel` recipes for the `tools` extension. For the full
API reference see [bzlmod hub-and-spoke](bzlmod_hub.md); to convert an existing
WORKSPACE project see [Migrating from WORKSPACE](bzlmod_migration.md).

> **You usually don't call `register_toolchains` yourself.**
> `rules_foreign_cc`'s own `MODULE.bazel` already registers
> `@rules_foreign_cc_toolchains//:all`, and bzlmod honors a dependency's
> registration for the whole build. Your `tools.<tool>(...)` tags shape what
> the hub contains; you don't need to re-register it or `use_repo` it. The
> only time you call `register_toolchains` / `use_repo` yourself is the
> [Bring your own toolchain](#bring-your-own-toolchain) case below, or when
> you reference a hub alias / spoke repo by name in your own BUILD files.

## Defaults only

Accept every tool's default mode and pinned version - just depend on
`rules_foreign_cc`:

```python
bazel_dep(name = "rules_foreign_cc", version = "{version}")
```

## Pin a single version

Override just cmake; every *other* tool keeps its default:

```python
bazel_dep(name = "rules_foreign_cc", version = "{version}")

tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.cmake(version = "3.31.12", mode = "binary")
```

Note: overriding a tool replaces *all* of rfcc's default tags for that tool,
not just the one you restate. cmake and ninja ship two defaults each - the
prebuilt binary plus an unconstrained `system` host-PATH fallback (see
[Minimal setup](bzlmod_hub.md#minimal-setup)) - so a lone
`tools.cmake(mode = "binary")` drops the cmake system fallback, and resolution
will fail on platforms rfcc has no prebuilt for. To keep the fallback, restate
both tags:

```python
tools.cmake(version = "3.31.12", mode = "binary")
tools.cmake(mode = "system")
```

## Track the latest patch of a minor series

Use a `major.minor.x` wildcard to take whatever patch `rules_foreign_cc`
ships for that minor series (here `3.31.x` resolves to `3.31.12`):

```python
tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.cmake(version = "3.31.x", mode = "binary")
```

## Build a tool from source

Force cmake to build from source instead of downloading a prebuilt binary:

```python
tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.cmake(version = "3.31.12", mode = "source")
```

## Use a host-installed tool

Skip downloading/building and use the tool already on the exec host. This is
not hermetic - the build depends on what's installed - but it's useful for
tools you don't want rules_foreign_cc to manage:

```python
tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.make(mode = "system")
tools.ninja(mode = "system")
```

## Full control with `tools.explicit()`

Suppress rfcc's default registrations entirely and register only what you
declare. Any
tool you don't tag has no registered toolchain, so resolution fails for it:

```python
tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.explicit()

tools.cmake(version = "3.31.12", mode = "binary")
tools.ninja(version = "1.13.2", mode = "binary")
tools.make(version = "4.4.1", mode = "source")
```

## Bring your own toolchain

Declare the spoke but register it yourself (e.g. with custom constraints or
conditional logic). `register_toolchain = False` suppresses the hub entry:

```python
# MODULE.bazel
tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.cmake(version = "3.31.12", mode = "binary", register_toolchain = False)
use_repo(tools, "cmake-3.31.12-linux-x86_64")

register_toolchains("//:cmake_tool_manual")
```

```python
# BUILD.bazel
toolchain(
    name = "cmake_tool_manual",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    toolchain = "@cmake-3.31.12-linux-x86_64//:cmake_tool",
    toolchain_type = "@rules_foreign_cc//toolchains:cmake_toolchain",
)
```

## No-op a tool you don't need to run

Some build systems require a toolchain to *resolve* even if the tool is never
run, or treat a tool as optional and simply skip the work when it's absent.
`mode = "noop"` registers a placeholder that satisfies resolution
(host-independent, unlike `mode = "system"`) and points the tool at a path
that fails when executed.

Whether that matters depends on the build: if nothing ever invokes the tool -
e.g. a cmake build that declares an m4 dependency it doesn't use, or
`pkgconfig` set to noop to skip optional package searches - the build succeeds
and just skips that step. If the build *does* invoke the tool, it fails loudly
at execution time rather than silently using a host binary.

```python
tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.explicit()

tools.cmake(version = "3.31.12", mode = "binary")
tools.ninja(version = "1.13.2", mode = "binary")
tools.m4(mode = "noop")
tools.pkgconfig(mode = "noop")
```
