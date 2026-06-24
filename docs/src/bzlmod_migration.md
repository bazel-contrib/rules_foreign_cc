# Migrating to the bzlmod hub

This page covers two migrations:

1. **From WORKSPACE** to bzlmod (`rules_foreign_cc_dependencies()` → the
   `tools` extension).
2. **From the previous bzlmod surface** (singleton spoke repos →
   version-suffixed spokes + hub aliases).

For the full API see [bzlmod hub-and-spoke](bzlmod_hub.md); for recipes see
[Examples](bzlmod_examples.md).

## From WORKSPACE

### Before (WORKSPACE)

```python
load("@rules_foreign_cc//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")

rules_foreign_cc_dependencies()
```

### After (MODULE.bazel)

```python
bazel_dep(name = "rules_foreign_cc", version = "{version}")
```

The `bazel_dep` alone reproduces the default tool set the WORKSPACE macro
registered - `rules_foreign_cc` registers the hub from its own MODULE.bazel,
and bzlmod honors that for the whole build. You only need the `tools`
extension if you want to customize versions or modes, and even then you don't
call `register_toolchains` yourself.

### Mapping the old kwargs

`rules_foreign_cc_dependencies(...)` took several flags. Here's where each one
goes under bzlmod:

| WORKSPACE kwarg | bzlmod equivalent |
|---|---|
| `register_default_tools = True` (cmake/ninja) | automatic; rfcc registers the hub for you |
| `register_built_tools = True` (build from source) | `tools.<tool>(mode = "source", version = "...")` (an explicit version is required), or the source defaults in the hub |
| `register_preinstalled_tools = True` (host tools) | `tools.<tool>(mode = "system")` |
| `cmake_version = "3.31.12"` | `tools.cmake(version = "3.31.12")` |
| `ninja_version = "1.13.2"` | `tools.ninja(version = "1.13.2")` |
| `make_version = "4.4.1"` | `tools.make(version = "4.4.1")` |
| `meson_version = "1.10.1"` | `tools.meson(version = "1.10.1")` |
| `pkgconfig_version = "0.29.2"` | `tools.pkgconfig(version = "0.29.2")` |
| `register_toolchains = False` | omit `register_toolchains(...)`; register manually |
| `native_tools_toolchains = [...]` | `tools.<tool>(..., register_toolchain = False)` + your own `toolchain(...)` |

### Selecting nmake by label (Windows)

If you build an MSVC target by pointing a rule's `toolchain` attribute at
`@rules_foreign_cc//toolchains:preinstalled_nmake_toolchain` (e.g.
`cmake(name = "hello_nmake", toolchain = "@rules_foreign_cc//toolchains:preinstalled_nmake_toolchain")`),
that label still resolves under bzlmod - it's a static target in
`rules_foreign_cc`, not something the hub generates. No change is needed;
you do **not** need a `tools.nmake(...)` tag for this.

nmake has no `noop` mode: it shares the `make` toolchain type, so a noop
nmake entry would carry no constraints and shadow the real make toolchain on
every platform. `tools.nmake(mode = "noop")` is rejected at evaluation time.
To no-op the make family, use `tools.make(mode = "noop")`.

### Running both during migration

You can keep your WORKSPACE working while you test the bzlmod path. Bazel
selects the dependency model with `--enable_bzlmod` / `--noenable_bzlmod`
(or the `common --enable_bzlmod` line in `.bazelrc`). Verify the bzlmod build
before deleting `WORKSPACE`.

Note: this release makes `rules_foreign_cc_dependencies()` create a repo named
`@rules_foreign_cc_toolchains` in WORKSPACE mode too (the hub that publishes
the source-spoke aliases macros like `meson_with_requirements` rely on). If
your own WORKSPACE already defines a repo by that name, rename yours to avoid
the collision.

## From the previous bzlmod surface

The version-suffixed source-archive repos replace the singleton names from the
previous release. There is **no zero-edit migration path**; pick whichever of
the patterns below matches what you reference in your BUILD files.

### A root module's version tags now take effect

The previous `tools` extension read its `cmake` / `ninja` version tags only
from non-root modules; a version set on the **root** module's own tag was not
applied, so the build kept rfcc's default version. The registered toolchains
are now driven by the root module's tags instead. (Transitive modules' tags
still fetch spokes for their own scope but, as before, don't shape the hub's
registration list - only the root and rfcc's own defaults do.) If your root
MODULE.bazel already carried a `tools.cmake(version = "...")` or
`tools.ninja(version = "...")` tag that previously had no effect, that version
now applies - confirm it's the version you want. (This only matters if the
pinned version differs from the default; if you weren't tagging cmake/ninja on
the root, nothing changes.)

### Drop the manual hub `use_repo` / `register_toolchains`

The previous bzlmod surface made you `use_repo` the extension's per-tool
toolchain repos and register them yourself:

```python
# Before -- previous bzlmod surface
use_repo(
    tools,
    "rules_foreign_cc_framework_toolchains",
    "cmake_3.31.12_toolchains",
    "ninja_1.13.2_toolchains",
    # ...source repos...
)
register_toolchains(
    "@rules_foreign_cc_framework_toolchains//:all",
    "@cmake_3.31.12_toolchains//:all",
    "@ninja_1.13.2_toolchains//:all",
)
```

`@rules_foreign_cc_framework_toolchains` is no longer the registration
surface. The framework toolchains are still registered - the hub now carries
them (the `00_framework` entries in `@rules_foreign_cc_toolchains`), and
`rules_foreign_cc` registers the hub from its own MODULE.bazel, so they
resolve with no `register_toolchains` line at all. The aggregator repo is
still minted, but nothing registers it and you no longer `use_repo` it.
Delete the `use_repo` entries and the `register_toolchains(...)` calls above;
leaving the `@rules_foreign_cc_framework_toolchains//:all` line in place would
redundantly re-register the same framework toolchains. You only add a
`register_toolchains("@rules_foreign_cc_toolchains//:all")` line back if you
opted out of rfcc's own registration.

The per-version binary aggregators (`@cmake_3.31.12_toolchains`,
`@ninja_1.13.2_toolchains`) aren't gone: a binary spoke still declares its
aggregator repo. What changed is that nothing registers their toolchains for
you and they're no longer in your `use_repo` list, so the hub's registrations
win by default. If you want manual binary registration you can still `use_repo`
one and register it yourself (see
[`register_toolchain = False`](bzlmod_hub.md#register_toolchain--false)). Most
consumers just delete the lines above and let the hub register the defaults.

`bazel mod tidy` will **not** clean these up for you: the `tools` extension
reports `reproducible = True` and declares no `use_repo`-able repos of its own
(the same as `go_sdk` and rules_python's `pip`), so `mod tidy` leaves the stale
entries in place. Remove them by hand.

Renamed source repos (singleton → version-suffixed at default versions):

| Before | After |
|---|---|
| `@cmake_src` | `@cmake_src_3.31.12` |
| `@meson_src` | `@meson_src_1.10.1` |
| `@gnumake_src` | `@make_src_4.4.1` |
| `@ninja_build_src` | `@ninja_src_1.13.2` |
| `@pkgconfig_src` | `@pkgconfig_src_0.29.2` |

The per-platform binary spoke repos were also renamed to one scheme,
`@<tool>-<version>-<os>-<arch>`, where `<os>` and `<arch>` are the Bazel
platform names. This affects only code that referenced a binary spoke by its
literal repo name (a `use_repo` entry or a hand-written `toolchain(...)`
pointing at one); the hub and the aggregator *repo* names above are unchanged,
so most consumers see nothing. The ninja spokes changed both separator and
token (`@ninja_1.13.2_linux` -> `@ninja-1.13.2-linux-x86_64`), and cmake's
upstream-derived platform tokens were normalized to Bazel spellings
(`@cmake-3.31.12-Linux-x86_64` -> `@cmake-3.31.12-linux-x86_64`,
`win64-x64` -> `windows-x86_64`). cmake's universal2 macOS build uses the arch
token `universal` (`@cmake-3.31.12-macos-universal`). See
[bzlmod hub-and-spoke](bzlmod_hub.md) for the full scheme. These per-platform
names are an implementation detail and not a stable API; pin the aggregator or
the hub rather than a spoke if you need a name that won't move.

The aggregator repos themselves keep their names, but their per-platform
`toolchain(...)` target names embed the spoke name, so those moved too
(`@ninja_1.13.2_toolchains//:ninja_1.13.2_linux_toolchain` ->
`@ninja_1.13.2_toolchains//:ninja-1.13.2-linux-x86_64_toolchain`).
Registering `@<tool>_<version>_toolchains//:all` is unaffected; only a
`register_toolchains(...)` pinned at one platform target by name needs the
update.

The public build-from-source toolchain labels were also removed; they are now
per-version spokes registered through the hub:

| Removed label | Replacement |
|---|---|
| `@rules_foreign_cc//toolchains:built_cmake_toolchain` | `tools.cmake(mode = "source", version = "3.31.12")` → hub registration |
| `@rules_foreign_cc//toolchains:built_ninja_toolchain` | `tools.ninja(mode = "source", version = "1.13.2")` → hub registration |
| `@rules_foreign_cc//toolchains:built_make_toolchain` | `tools.make(mode = "source", version = "4.4.1")` → hub registration |
| `@rules_foreign_cc//toolchains:built_meson_toolchain` | `tools.meson(mode = "source", version = "1.10.1")` → hub registration |
| `@rules_foreign_cc//toolchains:built_pkgconfig_toolchain` | `tools.pkgconfig(mode = "source", version = "0.29.2")` → hub registration |

If you registered these labels explicitly (e.g.
`register_toolchains("@rules_foreign_cc//toolchains:built_make_toolchain")`),
you have two replacements. Either drop the `register_toolchains(...)` line and
let the hub register a source-built default through
`@rules_foreign_cc_toolchains//:all` (declare the
`tools.<tool>(mode = "source", version = "...")` tag if you need a non-default
version), or keep registering by label and point at the source spoke's own
`toolchain(...)` target:
`register_toolchains("@make_src_4.4.1//:make_toolchain")`,
`register_toolchains("@meson_src_1.10.1//:meson_toolchain")`, and so on
(`@<tool>_src_<version>//:<tool>_toolchain`). The source spoke ships that
registerable `toolchain(...)` rule directly, unlike the binary per-platform
spokes, which expose only a `native_tool_toolchain` you have to wrap yourself
(see [`register_toolchain = False`](bzlmod_hub.md#register_toolchain--false)).

The autogenerated `@rules_foreign_cc//toolchains:cmake_versions.bzl` data file
(`CMAKE_SRCS`) was also removed. It was a "DO NOT MODIFY" generated table, not a
supported API; its data now lives at
[`toolchains/private/cmake_versions.bzl`](https://github.com/bazel-contrib/rules_foreign_cc/blob/main/toolchains/private/cmake_versions.bzl)
as `CMAKE_SRC_SRCS`. If you loaded the old path directly, drop the dependency.

### Pattern A - version-neutral, follow rfcc's defaults

If you don't care which version you get and want to track rfcc's defaults,
reach the source archive through the hub's version-neutral aliases:

```python
filegroup(
    name = "cmake_sources",
    srcs = ["@rules_foreign_cc_toolchains//:cmake_src_all"],
)
```

Hub aliases published per source-mode tool: `cmake_src_all`, `cmake_built`,
`make_src_all`, `make_built`, `meson_src_all`, `meson_built`,
`meson_src_meson_py`, `meson_src_runtime`, `ninja_src_all`, `ninja_built`,
`pkgconfig_src_all`, `pkgconfig_built`.

### Pattern B - pin the version yourself

If you want the version stable across rfcc upgrades, declare the spoke in your
MODULE.bazel and reference its version-suffixed name:

```python
# MODULE.bazel
tools.cmake(mode = "source", version = "3.21.7", register_toolchain = False)
use_repo(tools, "cmake_src_3.21.7")

# BUILD.bazel
filegroup(
    name = "cmake_sources",
    srcs = ["@cmake_src_3.21.7//:all_srcs"],
)
```

**Don't blindly rename.** Search-and-replacing `@cmake_src` →
`@cmake_src_3.31.12` without declaring an explicit
`tools.cmake(mode = "source", version = "3.31.12")` tag works *today* but
breaks silently the day rfcc bumps its default cmake version - the suffixed
repo will simply not exist. Either use Pattern A (hub alias) or Pattern B
(declare the tag).

## Common pitfalls

**Error:** `no such package '@cmake_src//...': The repository '@cmake_src'
could not be resolved`
**Solution:** The singleton source repos were renamed. Use the hub alias
`@rules_foreign_cc_toolchains//:cmake_src_all` (Pattern A) or the
version-suffixed `@cmake_src_<version>` after declaring the tag (Pattern B).

**Error:** `no such target '@rules_foreign_cc_toolchains//:cmake_src_all'`
under `tools.explicit()`
**Solution:** `tools.explicit()` drops the default source alias. Add an
explicit `tools.cmake(mode = "source", version = "...")` so the hub knows
which version to alias.

**Error:** `no such target
'@rules_foreign_cc_toolchains//:meson_src_meson_py'` when calling the
`meson_with_requirements` macro.
**Solution:** That public macro reaches the hub's meson source aliases (through
rfcc-owned `@rules_foreign_cc//foreign_cc:meson_src_*` aliases, so you do *not*
need to `use_repo` the hub yourself). It does need a meson source spoke to
exist. The defaults provide one automatically, but under
`tools.explicit()` you must declare `tools.meson(mode = "source", version =
"...")` yourself, otherwise the alias is never emitted.

**Error:** `While resolving toolchains for target ...: no matching toolchains
found for types @rules_foreign_cc//toolchains:cmake_toolchain`
**Solution:** Usually this means you used `tools.explicit()` and never tagged
that tool - under `tools.explicit()` you must declare every tool you want
registered. (You don't normally need a `register_toolchains(...)` line:
`rules_foreign_cc` registers the hub for you. You'd only add one if you
explicitly opted out of rfcc's registration.)

**Error:** a `tools.<tool>()` tag is rejected at evaluation time.
**Solution:** A bare tag with no attributes is invalid - it neither selects a
tool variant nor constrains one, so it's a no-op (`register_toolchain = False`
doesn't change that). Pass at least one of `mode`, `version`,
`exec_compatible_with`, or `target_compatible_with`.

**Error:** `no such target '@rules_foreign_cc//toolchains:built_cmake_toolchain'`
(or `built_ninja_toolchain` / `built_make_toolchain` / `built_meson_toolchain`
/ `built_pkgconfig_toolchain`)
**Solution:** The public `built_*_toolchain` labels were removed. The
build-from-source toolchains are now per-version spokes registered through the
hub. Declare a `tools.<tool>(mode = "source", version = "...")` tag (bzlmod) -- an
explicit version is required in `source`/`binary` mode -- so the hub registers
the source toolchain, or register the spoke's `:<tool>_toolchain` target by
label yourself: `register_toolchains("@make_src_4.4.1//:make_toolchain")`
(`@<tool>_src_<version>//:<tool>_toolchain` -- the source spoke ships a
registerable `toolchain(...)`; see
[`register_toolchain = False`](bzlmod_hub.md#register_toolchain--false)).

**Error:** build picks up the wrong tool version after an rfcc upgrade.
**Solution:** You were relying on a default version. Pin it with an explicit
`tools.<tool>(version = "...")` tag.

## Checklist

1. Add `bazel_dep(name = "rules_foreign_cc", version = "...")` to MODULE.bazel.
   (This alone registers the default toolchains - you do **not** add a
   `register_toolchains(...)` line for the hub.)
2. For any version or mode you pinned via `rules_foreign_cc_dependencies(...)`,
   add the matching `tools.<tool>(...)` tag (see the kwarg table above).
3. Replace any `@cmake_src` / `@meson_src` / etc. references with a hub alias
   (Pattern A) or a version-suffixed spoke (Pattern B).
4. Build with `--enable_bzlmod` and confirm parity:
   `bazel build //...`.
5. Inspect what got registered if anything looks off:
   `bazel query --output=build @rules_foreign_cc_toolchains//:all`.
6. Remove the WORKSPACE `rules_foreign_cc_dependencies()` call once green.
