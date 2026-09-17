# Runtime library search directories

## What this feature does

When a `foreign_cc` rule produces shared libraries or executables, those outputs
often depend on *other* shared libraries — from the rule's `deps`, its
`dynamic_deps`, or its own install tree. At run time the dynamic loader has to
find those `.so`/`.dylib` files. By default it can only find them via ambient
environment (`LD_LIBRARY_PATH` / `DYLD_LIBRARY_PATH`) or absolute paths baked in
by the upstream build — neither of which survives Bazel's sandbox or a
relocated install tree.

This feature makes `foreign_cc` derive **runtime library search directories**
(rpaths) and pass them to the upstream build system's link actions. The derived
paths are expressed relative to the loading object using `$ORIGIN` (Linux) or
`@loader_path` (macOS), so the installed outputs locate their shared-library
dependencies within the Bazel build with the loader environment unset.

In short: **the outputs become self-locating inside Bazel** — no
`LD_LIBRARY_PATH`, no absolute install paths.

The derived paths are computed in Bazel's runfiles/execroot coordinate space,
and the entries for dependency libraries point at Bazel's layout (e.g.
`external/<repo>/...` and the `_solib_*` symlink farm). This means the feature
resolves shared-library references **within the Bazel build and its runfiles**,
not in an install tree that has been copied or shipped outside Bazel. A target's
rpath to its *own* install tree (a binary finding its sibling `lib/`) is
`$ORIGIN`-relative and so survives relocation, but its rpaths to `deps` /
`dynamic_deps` libraries assume the Bazel layout.

## When to use it

| Situation | Use it? |
| --- | --- |
| You consume the `foreign_cc` output's shared libs / binaries from other Bazel targets and want them to run without `LD_LIBRARY_PATH` | **Yes** |
| The output is a binary that loads shared libs from its own install tree (e.g. `bin/app` → `lib/libfoo.so`) | **Yes** |
| The output depends on `deps` / `dynamic_deps` shared libs and must run inside the Bazel build / runfiles without `LD_LIBRARY_PATH` | **Yes** |
| You copy/ship the install tree *outside* Bazel and expect its `deps` references to keep resolving | No — derived dep paths assume Bazel's layout (see [Caveats](#caveats)) |
| The build produces only static libraries / headers (no shared libs or executables that load them) | Not needed |
| You target Windows C++ toolchains | Not supported (see [Caveats](#caveats)) |

## How to enable it

Enablement has two layers: a **per-target attribute** and a **global build
setting**. The per-target attribute is `runtime_library_search_directories` and
defaults to `auto`.

| Per-target attr value | Effect |
| --- | --- |
| `"auto"` *(default)* | Follow the global build setting |
| `"enabled"` | Force on for this target, regardless of the global setting |
| `"disabled"` | Force off for this target, regardless of the global setting |

The global build setting is
`@rules_foreign_cc//foreign_cc/settings:runtime_library_search_directories`. It
defaults to `disabled`.

| Global setting value | Effect on `auto` targets |
| --- | --- |
| `"disabled"` *(default)* | `auto` targets do **not** derive runtime paths |
| `"enabled"` | `auto` targets **do** derive runtime paths |

The resolved behavior is the combination of the two. The per-target attribute
takes precedence: `"enabled"` and `"disabled"` override the global setting
outright, and only `"auto"` defers to it.

| Per-target attr | Global setting | Result |
| --- | --- | --- |
| `auto` | `disabled` | Off |
| `auto` | `enabled` | On |
| `enabled` | *(any)* | On |
| `disabled` | *(any)* | Off |

### Enable for a single target

```python
load("@rules_foreign_cc//foreign_cc:defs.bzl", "make")

make(
    name = "libfoo",
    lib_source = ":srcs",
    out_shared_libs = ["libfoo.so"],
    # Turn the feature on just for this target.
    runtime_library_search_directories = "enabled",
    # Required for shared-lib outputs (see "Rule support" below).
    shared_ldflags_vars = ["LDFLAGS"],
    targets = ["", "install"],
)
```

### Enable globally

Flip the global setting on in your `.bazelrc` so every `auto` target opts in:

```text
# .bazelrc
build --@rules_foreign_cc//foreign_cc/settings:runtime_library_search_directories=enabled
```

Global enablement is a strict Unix-conformance switch: any Unix target that
declares shared-library outputs must then either wire up its shared-link flag
hook (below) or set `runtime_library_search_directories = "disabled"`.

## Rule support

| Rule | Supported | Shared-lib hook attr (required for `out_shared_libs`) |
| --- | --- | --- |
| `cmake` | Yes | *(automatic)* |
| `make` | Yes | `shared_ldflags_vars` |
| `configure_make` | Yes | `shared_ldflags_vars` |
| `meson` | Yes | `shared_ldflags_option` |
| `ninja` | No — fails if enabled | — |
| Boost (`boost_build`) | No — fails if enabled | — |
| `msbuild` | No (Windows) | — |

For `make`, `configure_make`, and `meson`, the derived shared-library linker
flags are handed to the upstream build through a named flag variable/option that
you forward into the actual link command. **When a target declares
`out_shared_libs` and the feature is enabled, the shared-lib hook attr is
required** — otherwise analysis fails, because the shared-library rpaths would
have nowhere to go. `cmake` injects the flags automatically through
`CMAKE_SHARED_LINKER_FLAGS_INIT` / `CMAKE_EXE_LINKER_FLAGS_INIT`, so no hook attr
is needed.

**Executable rpaths do not need a hook attr.** They flow through each rule's
default executable-linker route (for `make`/`configure_make`, the standard
`LDFLAGS` make variable), so no analysis error is raised for executables. The
`make`/`configure_make` `executable_ldflags_vars` attr is only needed when you
have repurposed `LDFLAGS` for shared libraries and want executable flags routed
to a *different* variable.

Example wiring the hook in a Makefile-based build:

```python
make(
    name = "mylib",
    lib_source = ":srcs",
    out_shared_libs = ["libmylib.so"],
    runtime_library_search_directories = "enabled",
    # rules_foreign_cc appends the derived rpath flags to these make vars,
    # which your Makefile must apply to the shared-library link command. Use a
    # dedicated variable here rather than LDFLAGS, which is the default route for
    # executable flags.
    shared_ldflags_vars = ["SHARED_LDFLAGS"],
    targets = ["", "install"],
)
```

### Additional search origins

By default the derived paths assume outputs live at their standard install
locations: `out_binaries` under `out_bin_dir` (defaults to `bin`) and
`out_shared_libs` under `out_lib_dir` (defaults to `lib`). If an output is
loaded from a *non-standard* location within the install tree, declare it so the
right relative paths are derived:

| Attribute | For | Meaning |
| --- | --- | --- |
| `additional_executable_runtime_library_search_origins` | executables | Extra install-tree-relative directories an executable may be loaded from |
| `additional_dynamic_runtime_library_search_origins` | shared libraries | Extra install-tree-relative directories a shared library may be loaded from |

Values are relative to the rule's install directory (e.g. `"libexec/bin"`,
`"lib/plugins"`) and should not include the lib name or the rule name. For each
origin, search directories are derived so an object loaded from there can still
find shared libraries from `deps`, `dynamic_deps`, and this rule's own shared
outputs.

```python
make(
    name = "app",
    lib_source = ":srcs",
    out_binaries = ["app"],
    out_shared_libs = ["libfoo.so"],
    runtime_library_search_directories = "enabled",
    # The binary is also installed/run from libexec/bin, not just bin.
    additional_executable_runtime_library_search_origins = ["libexec/bin"],
    shared_ldflags_vars = ["SHARED_LDFLAGS"],
    targets = ["", "install"],
)
```

## Caveats

- **Resolves inside the Bazel context, not for shipped install trees.** Derived
  paths are computed in Bazel's runfiles/execroot coordinate space, and the
  entries for `deps` / `dynamic_deps` libraries point at Bazel's layout
  (`external/<repo>/...`, the `_solib_*` symlink farm). They resolve when the
  output runs within the Bazel build or its runfiles. If you copy the install
  tree somewhere outside Bazel, only a target's `$ORIGIN`-relative references to
  its *own* install tree survive — its dependency rpaths will not.

- **Windows is not supported.** Setting `runtime_library_search_directories =
  "enabled"` on a target built with a Windows C++ toolchain is a hard analysis
  failure. Leaving it at `"auto"` is safe: global enablement is silently ignored
  on Windows.

- **`ninja` and Boost builds fail when enabled.** These rules do not implement
  runtime-search derivation; enabling it (explicitly or via the global setting)
  produces an analysis error rather than silently doing nothing. Use
  `runtime_library_search_directories = "disabled"` on those targets if you have
  enabled the feature globally.

- **macOS needs `@rpath` install names.** Derived rpaths only take effect if the
  installed Mach-O objects reference their dependencies through `@rpath/...`
  install names and load commands. This feature passes search directories to
  link actions but does **not** rewrite installed dylib IDs or load commands
  after the upstream install step. If the upstream build bakes absolute install
  names, you must make it emit or preserve `@rpath/...` names (e.g. via the
  build's own install-name settings or a post-install fixup).

- **Shared-lib outputs require the hook attr.** On `make`, `configure_make`, and
  `meson`, declaring `out_shared_libs` with the feature enabled but without the
  shared-link flag hook (`shared_ldflags_vars` / `shared_ldflags_option`) fails
  analysis. Either wire the hook or set
  `runtime_library_search_directories = "disabled"`.

- **Additional origins require qualifying outputs.** Setting an
  `additional_*_runtime_library_search_origins` attribute while the feature is
  disabled, or with no outputs that need runtime paths (no `out_shared_libs`,
  `out_binaries`, `out_data_dirs`, or `out_data_files`), fails analysis — the
  attribute would have no effect.
