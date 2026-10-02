# bzlmod hub-and-spoke

Under bzlmod, `rules_foreign_cc` exposes its toolchains through a single hub
repository, `@rules_foreign_cc_toolchains`. The hub holds two kinds of target:

- `toolchain(...)` entries, collected into a single `:all` target.
  `rules_foreign_cc` registers `@rules_foreign_cc_toolchains//:all` from its
  own `MODULE.bazel`, so every entry in it is a registered toolchain for the
  whole build. You do not register it yourself.
- version-neutral aliases (e.g. `cmake_src_all`) into the spoke repos, for
  BUILD files that need to reach an archive directly.

The underlying per-version "spoke" repos hold the actual tools; the hub just
points into them. Spoke names follow a fixed scheme per mode, so you can
predict a spoke's name rather than look it up:

- **Binary spokes** are named `@<tool>-<version>-<os>-<arch>`, e.g.
  `@cmake-3.31.12-linux-x86_64` and `@ninja-1.13.2-linux-x86_64` (target
  `:<tool>_tool`). A binary spoke exists only for a `mode = "binary"` tag:
  rfcc's default cmake is one, but its default ninja is `custom` over the
  `@ninja` registry module, so the ninja spoke above is only declared once a
  root writes `tools.ninja(mode = "binary", version = "1.13.2")` itself.
  `<os>` and `<arch>` are the Bazel platform names
  (`linux`/`macos`/`windows`, `x86_64`/`aarch64`/`x86_32`), so the suffix
  matches the toolchain's `exec_compatible_with` constraints. The one
  exception is cmake's macOS build: it ships a single universal2 binary that
  resolves for both `x86_64` and `aarch64` (so the toolchain carries no cpu
  constraint), and its arch token is `universal` -
  `@cmake-3.31.12-macos-universal`.
- **Source spokes** are named `@<tool>_src_<version>`, e.g.
  `@cmake_src_3.31.12`, `@make_src_4.4.1`, `@meson_src_1.10.1` (target
  `:<tool>_tool`). These hold the upstream release tarball, which
  `rules_foreign_cc` bootstraps into a working tool. m4 has no source spoke:
  it has never had a bootstrap, so `custom` is the only way to point it at a
  different m4.
- **Custom spokes** are named `@<tool>_custom_<target>`, with the target
  label flattened into a repo-name-safe token (`@@pkgconf+//:pkg-config` ->
  `pkgconf_pkg-config`). They hold nothing but generated BUILD text: an alias
  onto the target your tag named, and the `native_tool_toolchain` wrapping it.
  See [`custom` mode](#custom-mode).

For most users these names are an implementation detail: `rules_foreign_cc`
registers the hub and you never touch the spokes directly.

For copy-pasteable recipes see [Examples](bzlmod_examples.md); to move an
existing WORKSPACE project over, see
[Migrating from WORKSPACE](bzlmod_migration.md).

## How the hub is assembled

It helps to follow the chain from a tag to a registered toolchain, in order.

**Step 1 - each `tools.<tool>(...)` tag has up to two effects.** Every tag,
from any module (root or transitive) and regardless of `register_toolchain`,
**declares a spoke repo** for its tool/mode/version. Declaring is not
downloading: Bazel materializes a spoke lazily, only when something references
one of its targets (see [Non-root modules](#non-root-modules) and
[`register_toolchain = False`](#register_toolchain--false)). On top of that, a
tag that both comes from the **root** module and keeps the default
`register_toolchain = True` **adds a `toolchain(...)` entry to the hub**.
Non-root tags and `register_toolchain = False` tags only declare a spoke; they
never add a hub entry.

**Step 2 - `rules_foreign_cc` adds its own default entries.** For tools the
root didn't tag with a registering tag, rfcc contributes default
`toolchain(...)` entries (the pinned cmake/ninja/etc.). Root entries sort
ahead of rfcc's defaults in `:all`, so a registering root tag wins on conflict
for that tool. [`tools.explicit()`](#toolsexplicit) (root-only) drops rfcc's
default entries entirely, leaving only the root's own; spoke declaration from
Step 1 is unaffected.

**Step 3 - `rules_foreign_cc` registers the hub.** rfcc calls
`register_toolchains("@rules_foreign_cc_toolchains//:all")` from its own
[`MODULE.bazel`](https://github.com/bazel-contrib/rules_foreign_cc/blob/main/MODULE.bazel),
so every `toolchain(...)` entry collected in Steps 1-2 becomes a registered
toolchain for the whole build. You never call `register_toolchains` for the
hub yourself. This is also why `register_toolchain = False` suppresses
registration without suppressing the spoke: it withholds the Step 1 hub entry,
so there is nothing for Step 3 to register, but the spoke is still declared.

## Minimal setup

If you want sensible defaults and don't care about specific versions, just
depend on `rules_foreign_cc`:

```python
bazel_dep(name = "rules_foreign_cc", version = "{version}")
```

That's it. `rules_foreign_cc` contributes its default tool set - cmake as a
prebuilt binary, m4, make, meson, ninja and pkgconfig wrapped from the
`m4` / `make` / `meson` / `ninja` / `pkgconf` Bazel Central Registry modules
rfcc `bazel_dep`s on, plus autoconf, automake, and msbuild as system tools -
and **registers the hub for you** from its own MODULE.bazel. (For the exact
default mode and pinned
version of each tool, see the
[per-tool support table](#per-tool-support) below.) cmake
additionally registers an unconstrained `system` toolchain as a host-PATH
fallback: the prebuilt binary wins on the platforms rfcc ships prebuilts for,
and any other host falls back to a `cmake` on `PATH` rather than
failing resolution. The registry-backed tools need no such fallback - they
build from source, so they cover every platform with a C++ toolchain.
(nmake is *not* a default: it shares make's toolchain type, so it's selected
only by an explicit `toolchain =` label, never registered for resolution.)
bzlmod honors a dependency's `register_toolchains(...)` for the whole build, so
you don't call it yourself.

## The `tools` extension

Customisation goes through the `tools` module extension. You add only the tags
for the tools you care about; every other tool keeps its default, and you still
don't register anything yourself. (Tagging a tool replaces *all* of rfcc's
default tags for that one tool - relevant for cmake, which defaults to
a binary plus a `system` fallback; see the note in
[Minimal setup](#minimal-setup).)

```python
tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")

tools.cmake(version = "3.31.12", mode = "binary")
tools.ninja(mode = "system")
tools.make(mode = "system")  # use make from PATH
```

`use_repo(tools, "rules_foreign_cc_toolchains")` and
`register_toolchains("@rules_foreign_cc_toolchains//:all")` are only needed if
you reference the hub repo by name in your own BUILD files, or if you opt out
of rfcc's registration (see
[`register_toolchain = False`](#register_toolchain--false)).

### Declaring a tag is all-or-nothing

Omitting a `tools.<tool>(...)` tag entirely is how you accept rfcc's own
registration for that tool. Writing one commits you to specifying it
completely: every attribute defaults to empty, and nothing is inferred from
rfcc's defaults or from the rest of the tag.

| Attribute | Required when | Rejected when |
|---|---|---|
| `mode` | always | not one of the tool's supported modes |
| `version` | mode is `binary` or `source` | mode is `system`, `noop` or `custom`; tool is versionless |
| `target` | mode is `custom` | mode is not `custom` |

`mode` is checked first, so a bare or half-filled tag says so plainly rather
than failing later on a symptom. This is deliberate: with no mode there is
nothing to infer from. A `version` alone doesn't distinguish `binary` from
`source` (ninja's tables overlap), and constraints alone identify nothing.

`register_toolchain = False` does not relax any of this - it suppresses the
hub entry, not the declaration.

Each tool has its own tag class: `tools.autoconf`, `tools.automake`,
`tools.cmake`, `tools.m4`, `tools.make`, `tools.meson`, `tools.msbuild`,
`tools.ninja`, `tools.nmake`, `tools.pkgconfig`.

### Tag attributes

All `tools.<tool>(...)` tags share the same shape:

| Attribute | Type | Notes |
|---|---|---|
| `mode` | string | **Required.** One of the modes supported by the tool - see [Per-tool support](#per-tool-support). |
| `version` | string | Required when `mode` is `binary` or `source`; forbidden for `system`/`noop`/`custom` and for versionless tools. Accepts an exact patch (`3.31.12`) or a `major.minor.x` wildcard (`3.31.x`) that resolves to that minor series' latest patch - see [Version wildcards](#version-wildcards). |
| `target` | label | Required when `mode` is `custom`, forbidden otherwise. The executable to use as the tool - see [`custom` mode](#custom-mode). |
| `register_toolchain` | bool | Default `True`. If `False`, declare the spoke but skip registration - see below. |
| `exec_compatible_with` | label list | Forwarded to the registered `toolchain(...)` target's `exec_compatible_with`. |
| `target_compatible_with` | label list | Forwarded to the registered `toolchain(...)` target's `target_compatible_with`. |

### Per-tool support

| Tool | Supported modes | rfcc's own default | Versioned |
|---|---|---|---|
| `autoconf` | system, noop | system | no |
| `automake` | system, noop | system | no |
| `cmake` | binary, custom, source, system, noop | binary | yes |
| `m4` | custom, system, noop | custom (`@m4`) | no |
| `make` | custom, source, system, noop | custom (`@make`) | yes |
| `meson` | custom, source, system, noop | custom (`@meson`) | yes |
| `msbuild` | custom, system, noop | system | no |
| `ninja` | binary, custom, source, system, noop | custom (`@ninja`) | yes |
| `nmake` | system | system | no |
| `pkgconfig` | custom, source, system, noop | custom (`@pkgconf//:pkg-config`) | yes |

"rfcc's own default" is what you inherit by *not* writing a tag for that tool;
it is not a fallback within a tag you do write (see
[Declaring a tag is all-or-nothing](#declaring-a-tag-is-all-or-nothing)).

`autoconf`, `automake` and `nmake` have no `custom` mode. The first two drive
three and two environment variables respectively, which one binary cannot
satisfy; nmake has no environment variable at all. For those, register your
own `toolchain(...)` with `register_toolchain = False`.

The pinned default version for each versioned tool lives in
[`foreign_cc/private/tool_specs.bzl`](https://github.com/bazel-contrib/rules_foreign_cc/blob/main/foreign_cc/private/tool_specs.bzl)
(the `default_version` of each entry), the authoritative source for this whole
table. The version numbers are omitted here on purpose: they move on every
generator bump, and duplicating them in prose only invites drift.

### Version wildcards

A `version` may be an exact patch (`3.31.12`) or a `major.minor.x` wildcard
(`3.31.x`). A wildcard resolves to the latest patch `rules_foreign_cc` ships
for that minor series:

```python
tools.cmake(mode = "binary", version = "3.31.x")  # -> 3.31.12
```

Resolution happens before any repo is created, so the wildcard and the exact
patch are interchangeable: `version = "3.31.x"` materializes the same
`@cmake-3.31.12-<platform>` / `@cmake_src_3.31.12` spoke as
`version = "3.31.12"` would. This matches the WORKSPACE helpers
(`cmake_binary_spokes("3.31.x")`), so the two dependency models behave
identically.

An unknown wildcard (a minor series rfcc doesn't ship) is rejected with a
message listing the accepted exact versions and wildcards.

## `custom` mode

`mode = "custom"` points a toolchain at an executable your build already
produces - one you build yourself, or one from another module:

```python
tools.make(mode = "custom", target = "//tools/make:my_make")
tools.cmake(mode = "custom", target = "@some_module//:cmake")
```

`target` is a **plain executable**, not a `native_tool_toolchain`.
`rules_foreign_cc` generates the wrapper for you, into a spoke repo named
`@<tool>_custom_<flattened target label>`, and slots the resulting
`toolchain(...)` into the hub alongside every other entry. That placement is
the point: a `custom` tag participates in the hub's ordering (root tags ahead
of rfcc's defaults) and honours `exec_compatible_with` /
`target_compatible_with`, which a hand-written `toolchain(...)` registered
outside the hub cannot do.

This is how rfcc reaches its own default m4, make and pkg-config: its
`MODULE.bazel` carries `tools.m4(mode = "custom", target = "@m4")` and
friends over the Bazel Central Registry modules it `bazel_dep`s on.

Two constraints are worth knowing before you use it:

- **The target must be visible to the spoke.** The generated alias lives in a
  repo of its own, so a `//visibility:private` target fails analysis with a
  visibility error naming a repo you never wrote. Mark it
  `//visibility:public`.
- **The alias does not rename the file.** `rules_foreign_cc` symlinks the tool
  into `$EXT_BUILD_DEPS/bin` under the *underlying file's* basename, not the
  alias's. That only matters for tools something else looks up by name on
  `PATH` - which is why rfcc's own pkgconfig default points at
  `@pkgconf//:pkg-config` and not `@pkgconf//:pkgconf`. ninja is handled for
  you: rfcc routes it through a wrapper literally named `ninja`, because
  meson's and CMake's dependency search insist on finding one.

`version` is rejected on a `custom` tag: the tag names the binary outright, so
there is nothing left for rfcc to pick a version of.

## `source` mode and table staleness

`mode = "source"` builds the tool from its upstream release tarball. The
versions available are whatever `rules_foreign_cc` carries download URLs and
build files for, which is **not** the same set as the registry modules rfcc
defaults to:

- **pkgconfig** source mode is **pkg-config 0.29.2** - a different, long
  unmaintained program from the **pkgconf 3.0.7** that `custom` mode
  defaults to.
- **ninja** and **make** source tables trail their prebuilt/registry
  counterparts.

These tables are stale by nature: keeping a hand-maintained bootstrap current
is exactly what the registry modules exist to avoid. Prefer `binary` or
`custom` unless you specifically need the tool built from source in your own
toolchain, and treat a `source` version as pinned rather than tracking.

## `tools.explicit()`

By default, `rules_foreign_cc` contributes a baseline set of registrations
into the hub so that downstream consumers Just Work. If you want full
control:

> **Caution:** `tools.explicit()` suppresses rfcc's default registrations entirely.
> Any tool you don't tag has **no registered toolchain**, so toolchain
> resolution fails for it (`no matching toolchains found for ...`). When you
> opt in, you must declare every tool your build actually uses.

```python
tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.explicit()

tools.cmake(version = "3.31.12", mode = "binary")
tools.ninja(version = "1.13.2", mode = "binary")
# ...declare every tool you want, or accept that resolution will fail for
# the ones you skipped.
```

`tools.explicit()` is a root-only opt-out. After it fires, the rfcc-default
contributions are dropped entirely and the only registrations in the hub are
those your root MODULE.bazel asks for.

`tools.explicit()` gates **registration and singleton hub aliases** only -
it does not suppress spoke declaration. Spokes that any module (root or
transitive) requests via `tools.<tool>(...)` are still declared (and
materialized on reference), so a transitive dependency that says
`tools.cmake(version="3.21.7", register_toolchain=False)` to reach a
specific archive in its own scope keeps working under `tools.explicit()`.
You just won't see those versions in the hub's `:all` list unless your
root asks for them.

## Non-root modules

Non-root `tools.<tool>(...)` tags declare their spoke (so the per-version
repo is reachable inside that module's scope, materialized when referenced)
but never contribute hub registrations or singleton aliases. The result: a
transitive module pinned to a specific tool version keeps working
without leaking that pin into the root's toolchain registration list.

If a transitive module wants `cmake 3.21.7` and root wants `cmake 3.31.12`,
both `@cmake_src_3.21.7` and the root's binary spoke
(`@cmake-3.31.12-<platform>`) are declared; the root's version is the
registered toolchain of record.

## `register_toolchain = False`

If you want the spoke declared (so the underlying repo and its targets are
reachable, and materialized when you reference them) but you don't want it
added to the hub's `:all` registration list - for example, because you're
doing your own conditional registration - pass `register_toolchain = False`:

```python
tools.cmake(version = "3.31.12", mode = "binary", register_toolchain = False)
use_repo(tools, "cmake-3.31.12-linux-x86_64")
```

Binary and source spokes differ in what they expose, so manual registration
differs too:

**Binary per-platform spokes** ship only a `native_tool_toolchain`
implementation target (`:cmake_tool`), not a `toolchain(...)` rule, so a bare
`register_toolchains(...)` against it isn't enough. Wrap it in your own
`toolchain(...)` with the appropriate `toolchain_type` and constraints, then
register that:

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

```python
# MODULE.bazel
register_toolchains("//:cmake_tool_manual")
```

**Source spokes** ship a registerable `toolchain(...)` rule directly, at
`@<tool>_src_<version>//:<tool>_toolchain`, so you register it by label
without wrapping anything:

```python
# MODULE.bazel
register_toolchains("@cmake_src_3.31.12//:cmake_toolchain")
```

(The source spoke also exposes the underlying `:<tool>_tool` implementation
target if you want to wrap it yourself, but you rarely need to.)

## Built-in noop toolchains

`rules_foreign_cc` ships `noop_<tool>_toolchain` targets for every
noop-capable tool (`nmake` has no noop mode -- it shares the `make` toolchain
type, so use `tools.make(mode = "noop")` to no-op the make family):

- `@rules_foreign_cc//toolchains:noop_autoconf_toolchain`
- `@rules_foreign_cc//toolchains:noop_automake_toolchain`
- `@rules_foreign_cc//toolchains:noop_cmake_toolchain`
- `@rules_foreign_cc//toolchains:noop_m4_toolchain`
- `@rules_foreign_cc//toolchains:noop_make_toolchain`
- `@rules_foreign_cc//toolchains:noop_meson_toolchain`
- `@rules_foreign_cc//toolchains:noop_msbuild_toolchain`
- `@rules_foreign_cc//toolchains:noop_ninja_toolchain`
- `@rules_foreign_cc//toolchains:noop_pkgconfig_toolchain`

Each one points its tool at `false` and exports the canonical env vars
(`CMAKE`, `NINJA`, `M4`, etc.) pointing at the same. They make analysis
succeed - toolchain resolution finds something - and execution fail loudly.
This is intended for tests and other targets that need to build but never
actually invoke the underlying tool. `tools.<tool>(mode = "noop")` is the
extension-driven way to register one of these.

## Limitations

The current surface does not handle these cases:

- **Major-only wildcards.** A `version` is an exact patch or a `major.minor.x`
  wildcard (see [Version wildcards](#version-wildcards)); a bare major series
  like `3.x` is not accepted.
- **Versions rfcc doesn't ship.** A `version` must resolve to a version
  `rules_foreign_cc` has download URLs for. To use a version rfcc doesn't
  carry, build it yourself and point a
  [`custom` tag](#custom-mode) at the result.
- **`custom` for autoconf, automake and nmake.** These drive more than one
  environment variable (or none), so one executable can't stand in for the
  toolchain; see [Per-tool support](#per-tool-support).
- **Only the root shapes the default registration set.** Non-root modules can
  declare spokes for their own scope but cannot append to the hub's `:all`
  registration list; that list is driven by the root module and rfcc's
  defaults.
