# News

## Unreleased

This is the first entry in the resumed changelog. Changes below are listed
relative to [0.15.1](https://github.com/bazel-contrib/rules_foreign_cc/releases/tag/0.15.1)
(released 2025-06-24); releases between the historical notes below and 0.15.1
were not tracked here.

### Breaking changes

- **Bazel 8 is now required for `bzlmod`.** The primary tested Bazel version
  moved to 8.6.0. Bazel 7 is still supported, but only in `WORKSPACE` mode; if
  you use `bzlmod` you must be on Bazel 8 or newer
  ([#1514](https://github.com/bazel-contrib/rules_foreign_cc/pull/1514)).
- **Built toolchains now ship only the latest patch of each minor series.** You
  can request a `<major>.<minor>.x` wildcard (e.g. `cmake_version = "3.19.x"`)
  which resolves to the newest known patch of that series. The exact-latest
  version string still works, but other previously-valid exact patch versions
  now fail ([#1559](https://github.com/bazel-contrib/rules_foreign_cc/pull/1559)).
- **Several default built-tool versions changed**, so unpinned users get the
  newer version automatically. The default built `meson` jumped from 1.5.1 to
  1.10.1 (a five-minor jump that can change meson behavior; fixes builds under
  apple-clang 17 / Xcode 26)
  ([#1473](https://github.com/bazel-contrib/rules_foreign_cc/pull/1473)), and the
  default `cmake` (3.31.8 → 3.31.12) and `ninja` (1.13.0 → 1.13.2) moved with the
  latest-patch-per-minor change above
  ([#1559](https://github.com/bazel-contrib/rules_foreign_cc/pull/1559)). Pin
  the relevant `*_version` argument of `rules_foreign_cc_dependencies` if you
  need the previous version.
- **Unrecognized platforms now fail the build instead of warning.** An unknown
  target/host OS or CPU (or an unmapped processor/target-OS parameter) now
  errors out rather than silently falling back to a native compile. Builds that
  previously limped along on an unrecognized platform will need a platform-data
  update ([#1490](https://github.com/bazel-contrib/rules_foreign_cc/pull/1490),
  building on [#1438](https://github.com/bazel-contrib/rules_foreign_cc/pull/1438)).

### New features

- **New `msbuild` rule** for building MSBuild (`.vcxproj`/`.sln`) projects with
  `MSBuild.exe` from MSVC. Only the pre-installed toolchain is supported
  ([#1443](https://github.com/bazel-contrib/rules_foreign_cc/pull/1443)).
- **New `resource_size` attribute** on all build rules
  (`default`/`tiny`/`small`/`medium`/`large`/`enormous`, plus a fixed
  single-CPU `serial`). It declares the action's CPU/RAM footprint to the Bazel
  scheduler and forwards parallelism env vars (`CMAKE_BUILD_PARALLEL_LEVEL`,
  `GNUMAKEFLAGS`, `MESON_NUM_PROCESSES`, `NINJA_JOBS`) to the underlying build
  system. Defaults can be overridden via `bazel run @rules_foreign_cc//foreign_cc/settings`
  ([#1465](https://github.com/bazel-contrib/rules_foreign_cc/pull/1465),
  [#1511](https://github.com/bazel-contrib/rules_foreign_cc/pull/1511)). For
  sized targets, the build tool may use the reserved CPU count plus 2 (tunable
  via `--@rules_foreign_cc//foreign_cc/settings:parallelism_overcommit`);
  `serial` is exempt and always runs `-j1`
  ([#1533](https://github.com/bazel-contrib/rules_foreign_cc/pull/1533)).
- **Output validation in-action** via the new
  `experimental_validate_outputs_in_action` attribute (default on). When an
  expected installed output is missing, the build now fails with a clear
  message that lists nearby/similarly-named files and preserves the temp tree,
  instead of Bazel's opaque "output was not created" error. Disable per-target
  with `experimental_validate_outputs_in_action = False`
  ([#1517](https://github.com/bazel-contrib/rules_foreign_cc/pull/1517)).
- **Opt-in short build paths on Windows** via the
  `--@rules_foreign_cc//foreign_cc/settings:allow_building_in_tmp` flag
  (default off), which relocates the build tree under `$TMP` to stay below the
  260-char `MAX_PATH` limit
  ([#1527](https://github.com/bazel-contrib/rules_foreign_cc/pull/1527)).
- **`set_file_prefix_map` is now available on the built-tool rules** (in
  addition to the main rules), and a new
  `--@rules_foreign_cc//foreign_cc/settings:set_file_prefix_map_default` flag
  turns it on globally; the per-rule attribute still wins. This strips sandbox
  paths via `-ffile-prefix-map` to improve build reproducibility (skipped on
  MSVC) ([#1545](https://github.com/bazel-contrib/rules_foreign_cc/pull/1545),
  groundwork in [#1553](https://github.com/bazel-contrib/rules_foreign_cc/pull/1553)).
- **`boost_build` and the built `ninja` tool now honor toolchain `copts`/`linkopts`**
  (previously advertised but ignored)
  ([#1554](https://github.com/bazel-contrib/rules_foreign_cc/pull/1554)).
- **`ninja` now wires up the cc toolchain's C build variables** (compilers,
  flags, pkg-config, and dependency env) the same way `make` does, instead of
  relying on tools found on `PATH`. Existing `ninja()` targets now build with the
  configured toolchain
  ([#1477](https://github.com/bazel-contrib/rules_foreign_cc/pull/1477)).
- **`meson` gains a `shared_ldflags_option` attribute** that routes
  shared-library linker flags into a named meson build option, fixing
  `shared_library()` link failures when executable-only flags such as `-pie`
  are present; `options` values are now location/make-variable expanded
  ([#1401](https://github.com/bazel-contrib/rules_foreign_cc/pull/1401)).
- **`make` and `configure_make` gain `dynamic_module_ldflags_vars`** for
  loadable-module (plugin) linker flags, kept separate from shared-library
  flags. This is primarily for Darwin, where module links use `-bundle`
  ([#1542](https://github.com/bazel-contrib/rules_foreign_cc/pull/1542)).
- **`configure_make` now stubs autotools regen tools** (`ACLOCAL`, `AUTOCONF`,
  `AUTOMAKE`, etc.) so builds don't spuriously trigger regen recipes that break
  on RBE or hosts lacking those tools. The new `unstubbed_regen_tools`
  attribute lets a target opt specific tools back in
  ([#1544](https://github.com/bazel-contrib/rules_foreign_cc/pull/1544)).
- **`out_data_dirs` and `out_data_files` contents are now exposed as output
  groups**, so you can reference them directly instead of going through
  `gen_dir` or a genrule
  ([#1451](https://github.com/bazel-contrib/rules_foreign_cc/pull/1451),
  [#1464](https://github.com/bazel-contrib/rules_foreign_cc/pull/1464)).
- **`cmake` cross-compilation gains more targets:** `armv7` and `x86_32` CPUs
  with OS-aware `CMAKE_SYSTEM_PROCESSOR` values (fixing Android armeabi-v7a/x86
  builds) ([#1555](https://github.com/bazel-contrib/rules_foreign_cc/pull/1555)),
  iOS/tvOS/watchOS `CMAKE_SYSTEM_NAME` mappings
  ([#1495](https://github.com/bazel-contrib/rules_foreign_cc/pull/1495)), and
  macOS as a cross-compile target
  ([#1438](https://github.com/bazel-contrib/rules_foreign_cc/pull/1438)).
- **`cmake` sets `CMAKE_OSX_SYSROOT` automatically** on macOS from the hermetic
  sysroot, so cmake honors it instead of searching for Xcode
  ([#1361](https://github.com/bazel-contrib/rules_foreign_cc/pull/1361)).

### Bug fixes

**cmake**

- Default `CMAKE_MSVC_DEBUG_INFORMATION_FORMAT` to `Embedded` (`/Z7`) and
  replace `/Zi`, fixing intermittent "PDB API call failed" (C1090) errors when
  building multiple cmake targets in parallel on Windows. This changes the
  default debug-info format for anyone who hasn't set the cache variable
  explicitly (embedded in `.obj` rather than a separate `.pdb`)
  ([#1483](https://github.com/bazel-contrib/rules_foreign_cc/pull/1483)).

**meson**

- Fix the CMake-based dependency fallback by restoring the `ninja` wrapper name
  and adding `make` as a dependency, so meson/cmake dependency lookups resolve
  correctly ([#1506](https://github.com/bazel-contrib/rules_foreign_cc/pull/1506)).
- Export `AR` and `STRIP` from the cc toolchain so meson uses the hermetic
  archiver/stripper ([#1302](https://github.com/bazel-contrib/rules_foreign_cc/pull/1302)).
- Fix `meson_with_requirements` so Python modules declared as requirements are
  found when meson re-invokes python directly
  ([#1487](https://github.com/bazel-contrib/rules_foreign_cc/pull/1487)).
- A value set via `target_args["setup"]` is no longer clobbered by the empty
  deprecated `setup_args`, and the deprecation only fails when the deprecated
  arg is actually set
  ([#1444](https://github.com/bazel-contrib/rules_foreign_cc/pull/1444)).

**Framework (applies across rules)**

- `$$EXT_BUILD_DEPS$$` references in user attributes are now properly escaped so
  they survive make-variable expansion into the generated build scripts
  ([#1496](https://github.com/bazel-contrib/rules_foreign_cc/pull/1496)).
- Honor `--force_pic`: objects are now built position-independent when the
  toolchain requires PIC for dynamic libraries, fixing shared-library link
  errors ([#1440](https://github.com/bazel-contrib/rules_foreign_cc/pull/1440)).
- Fix directory symlinks in subdirectories that produced dangling links
  ([#1469](https://github.com/bazel-contrib/rules_foreign_cc/pull/1469)).
- Resolve the Apple SDK root via `xcrun --sdk` without the deprecated
  `APPLE_SDK_VERSION_OVERRIDE` suffix, fixing builds with non-standard SDK names
  ([#1467](https://github.com/bazel-contrib/rules_foreign_cc/pull/1467)).
- Populate `RANLIB` from the toolchain when available instead of always using a
  no-op (`:`), fixing parallel builds (e.g. openssl) that need a real ranlib
  ([#1509](https://github.com/bazel-contrib/rules_foreign_cc/pull/1509)).
- Variant toolchain attributes (`toolchain`/`extra_toolchain`) accept `select()`
  again and `extra_toolchain` is now optional
  ([#1466](https://github.com/bazel-contrib/rules_foreign_cc/pull/1466),
  fixing a regression from
  [#1459](https://github.com/bazel-contrib/rules_foreign_cc/pull/1459)).

**Built pkg-config / make tools**

- Fix building the from-source `pkg-config` tool on Windows
  ([#1459](https://github.com/bazel-contrib/rules_foreign_cc/pull/1459)),
  compile it with `-std=gnu90` to fix failures on newer compilers (e.g. glib)
  ([#1458](https://github.com/bazel-contrib/rules_foreign_cc/pull/1458)), and
  prefer the fast `mirror.bazel.build` download mirror
  ([#1445](https://github.com/bazel-contrib/rules_foreign_cc/pull/1445)).
- Append toolchain `-isystem` include flags to `CC`/`LD` (not just `CFLAGS`)
  when bootstrapping the built `make` and `pkg-config` tools, fixing configure
  scripts that need toolchain-provided system headers
  ([#1470](https://github.com/bazel-contrib/rules_foreign_cc/pull/1470)).
- Symlink a tool's `.runfiles` alongside it when symlinking tools into the
  build's `bin` directory, so hermetic autotools can find their runfiles data
  ([#1434](https://github.com/bazel-contrib/rules_foreign_cc/pull/1434)).

### Dependencies and toolchains

- **Bazel 9 compatibility:** load `CcSharedLibraryInfo` directly from `rules_cc`
  and upgrade `rules_cc` to 0.2.18, so the rules are consumable under Bazel 9
  ([#1493](https://github.com/bazel-contrib/rules_foreign_cc/pull/1493),
  [#1552](https://github.com/bazel-contrib/rules_foreign_cc/pull/1552)).
- The built `make` tool (4.4 and 4.4.1) is now reproducible across machines,
  improving cache hit rates
  ([#1543](https://github.com/bazel-contrib/rules_foreign_cc/pull/1543)).
- Updated bundled dependency versions, including a new `bazel_lib` dependency
  and bumps to `rules_python` 1.9.0, `bazel_skylib`, `platforms`, `rules_cc`,
  `rules_shell`, `rules_perl`, and `rules_rust`, mainly to resolve bzlmod
  version-mismatch warnings and keep lockfiles reproducible
  ([#1462](https://github.com/bazel-contrib/rules_foreign_cc/pull/1462),
  [#1486](https://github.com/bazel-contrib/rules_foreign_cc/pull/1486),
  [#1489](https://github.com/bazel-contrib/rules_foreign_cc/pull/1489),
  [#1482](https://github.com/bazel-contrib/rules_foreign_cc/pull/1482),
  [#1492](https://github.com/bazel-contrib/rules_foreign_cc/pull/1492)). The
  `rules_python` download URL also moved to the `bazel-contrib` GitHub org
  ([#1500](https://github.com/bazel-contrib/rules_foreign_cc/pull/1500)).

### Internal

- Faster builds: `copy_dir_contents_to_dir` batches its `touch -r` calls
  (~22% lower wall-time on darwin/windows example jobs)
  ([#1549](https://github.com/bazel-contrib/rules_foreign_cc/pull/1549)).
- Refactors with no behavior change: extracted common framework attributes
  ([#1553](https://github.com/bazel-contrib/rules_foreign_cc/pull/1553)),
  bazelrc-shim plumbing
  ([#1546](https://github.com/bazel-contrib/rules_foreign_cc/pull/1546)),
  data-driven prebuilt-toolchain generation
  ([#1561](https://github.com/bazel-contrib/rules_foreign_cc/pull/1561)), and
  use of rules_cc's `msvc-cl` config_setting
  ([#1562](https://github.com/bazel-contrib/rules_foreign_cc/pull/1562)).
- Removed the legacy Bazel-4-era platform config_settings in favor of
  `@platforms//os:...`
  ([#1474](https://github.com/bazel-contrib/rules_foreign_cc/pull/1474)).
- Removed the `cmake_android` example (core Android support is unchanged)
  ([#1471](https://github.com/bazel-contrib/rules_foreign_cc/pull/1471)).
- Extensive CI, test-harness, formatting, example, and download-mirror work
  across many PRs, including the move to a single `bazel test` phase
  ([#1548](https://github.com/bazel-contrib/rules_foreign_cc/pull/1548)),
  porting examples to bzlmod
  ([#1498](https://github.com/bazel-contrib/rules_foreign_cc/pull/1498)), and
  enabling many third-party examples on Windows.

**March 2021:**

These rules are now maintained by the community.

_Note_: After this release we will be bumping the minimum tested version to _4.0.0_.

- Added repository rules for downloading prebuilt versions of cmake and ninja
  rather than relying on system installed tools.

- Added native ninja build rule

- Now builds under the Bazel sandbox rather than in `/tmp`

- Tidied up the structure of the examples directory

- Deprecated the old rules `install_ws_dependency` and `cc_configure_make`

- Autogenerated documentation was added

**March 2019:**

- Support for versions earlier than 0.22 was removed.

- Tests on Bazel CI are running in the nested workspace

**January 2019:**

- Bazel 0.22.0 is released, no flags are needed for this version, but it does not work on Windows (Bazel C++ API is broken).

- Support for versions earlier than 0.20 was removed.

- [rules_foreign_cc take-aways](https://docs.google.com/document/d/1ZVvzvkUVTkPCzI-2z4S4VrSNu4kdaBknz7UnK8vaoZU/edit?usp=sharing) describing the recent work has been published.

- Examples package became the separate workspace.
  This also allows to illustrate how to initialize rules_foreign_cc.

- Native tools (cmake, ninja) toolchains were introduced.
  Though the user code does not have to be changed (default toolchains are registered, they call the preinstalled binaries by name.),
  you may simplify usage of ninja with the cmake_external rule and call it just by name.
  Please see examples/cmake_nghttp2 for ninja usage, and WORKSPACE and BUILD files in examples for the native tools toolchains usage
  (the locally preinstalled tools are registered by default, the build as part of the build tools are used in examples).
  Also, in examples/with_prebuilt_ninja_artefact you can see how to download and use prebuilt artifact.

- Shell script parts were extracted into a separate toolchain.
  Shell script inside framework.bzl is first created with special notations:
  - `export var_name=var_value` for defining the environment variable
  - `$$var_name$$` for referencing environment variable
  - `` `shell_command <space-separated-maybe-quoted-arguments>` `` for calling shell fragment

  The created script is further processed to get the real shell script with shell parts either
  replaced with actual fragments or with shell function calls (functions are added into the beginning of the script).
  Extracted shell fragments are described in commands.bzl.

  Further planned steps in this direction: testing with RBE, shell script fragments for running on Windows without msys/mingw,
  tests for shell fragments.
