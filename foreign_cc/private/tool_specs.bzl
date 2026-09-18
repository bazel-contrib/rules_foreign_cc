"""Per-tool metadata: modes, default versions, known versions, noop env vars.

Single source of truth shared by foreign_cc/extensions.bzl and
toolchains/private/noop_toolchains.bzl. Edit this module when bumping default
versions, adding tools, or adjusting noop env vars.

`known_versions` is a list-or-None of versions accepted in
`tools.<tool>(version = ...)`. None means "this tool takes no version in any
mode." For tools with more than one versioned mode the list is the union of
those modes' tables; the union is only an outer bound, because `tag_error`
re-checks the version against the named mode's own table. ninja -- whose
prebuilt releases and source archives overlap without coinciding -- is why:
it rejects `mode = "binary", version = "1.12.0"` on that second pass.
"""

# The version dicts under //toolchains/private declare a top-of-file
# `visibility([...])` that explicitly allows //foreign_cc/private to load
# them; buildifier's bzl-visibility heuristic only inspects path layout
# and doesn't honor the directive. Suppress the lint here.
# buildifier: disable=bzl-visibility
load("//toolchains/private:cmake_versions.bzl", "CMAKE_BIN_SRCS", "CMAKE_SRC_SRCS")

# buildifier: disable=bzl-visibility
load("//toolchains/private:make_versions.bzl", "GNUMAKE_SRCS")

# buildifier: disable=bzl-visibility
load("//toolchains/private:meson_versions.bzl", "MESON_SRCS")

# buildifier: disable=bzl-visibility
load("//toolchains/private:ninja_versions.bzl", "NINJA_BIN_SRCS", "NINJA_SRC_SRCS")

# buildifier: disable=bzl-visibility
load("//toolchains/private:pkgconfig_versions.bzl", "PKGCONFIG_SRCS")

def _is_exact_version(version):
    """True for an exact version key (not a `major.minor.x` wildcard).

    Accepts both `major.minor.patch` and bare `major.minor` keys, since some
    upstreams release two-component versions. Only the `.x` wildcard alias
    keys are excluded.
    """
    parts = version.split(".")
    return len(parts) >= 2 and parts[-1] != "x"

def _version_tuple(version):
    """Numeric tuple for ordering version keys; shorter keys sort lower.

    `4.4` -> (4, 4) sorts below `4.4.1` -> (4, 4, 1), so the latest patch in a
    minor series wins in `_wildcards_for`.
    """
    return tuple([int(p) for p in version.split(".")])

def exact_versions(*dicts):
    """Sorted union of the exact-patch keys across the given version dicts.

    The source dicts (e.g. CMAKE_SRC_SRCS) carry duplicate `a.b.x` wildcard
    keys alongside their exact patches; those are filtered out here so
    `known_versions` is exact-only. Wildcards are handled separately via
    `_wildcards_for`.

    Args:
        *dicts: version tables, keyed by version. Only the keys are read.

    Returns:
        A sorted list of the exact version keys, wildcards excluded.
    """
    seen = {}
    for d in dicts:
        for k in d.keys():
            if _is_exact_version(k):
                seen[k] = True
    return sorted(seen.keys())

def _wildcards_for(versions):
    """Map ``{"a.b.x": "a.b.c"}`` from a list of exact versions.

    Each `major.minor.x` resolves to the latest exact version in that series.
    Today's tables ship one patch per minor so there's never a contest, but
    the tie-break is what makes `a.b.x` mean "newest a.b" rather than
    "whichever key happened to sort last".
    """
    out = {}
    for version in versions:
        parts = version.split(".")
        key = "{}.{}.x".format(parts[0], parts[1])
        if key not in out or _version_tuple(version) > _version_tuple(out[key]):
            out[key] = version
    return out

# Mode constants. Use these strings everywhere.
MODE_BINARY = "binary"
MODE_CUSTOM = "custom"
MODE_SOURCE = "source"
MODE_SYSTEM = "system"
MODE_NOOP = "noop"

ALL_MODES = [MODE_BINARY, MODE_CUSTOM, MODE_SOURCE, MODE_SYSTEM, MODE_NOOP]

# Per-tool metadata.
#
# `default_mode` is the mode rules_foreign_cc's own MODULE.bazel registers for
# the tool. It is not a fallback: a tag must name its mode (see `tag_error`).
# A module that declares no tag for a tool inherits rfcc's registration, and
# this field is what models that for tests and docs.
#
# The three `custom_*` fields describe what a `custom` toolchain generates;
# they are None together on the tools that offer no `custom` mode (autoconf and
# automake set three and two variables naming different binaries, which one
# `target` cannot satisfy; nmake sets none). Whether the mode is *offered* is
# `spec.modes`, which is what `tag_error` checks. `custom_env_var` is the one
# environment variable the toolchain sets. `custom_alias_name` is the name rfcc
# gives the generated alias -- pkg-config, not pkgconf, because the framework
# symlinks the tool into $EXT_BUILD_DEPS/bin under its own basename.
# `custom_launcher` is a wrapper the tool must be invoked through rather than
# directly, which only ninja needs.
#
# `workspace_bcr_toolchain` is the prebuilt `native_tool_toolchain` that the
# WORKSPACE path registers for a tool backed by a registry module (@m4, @make,
# @ninja, @pkgconf). Bzlmod does not read it: there a `custom` tag points at
# the module's binary directly. A non-None `bcr_binary` is what marks a tool as
# registry-backed -- see `BCR_BACKED_TOOLS`.
#
# Every spec spells out every field, including the Nones, so readers and
# callers never have to guess a default.
TOOL_SPECS = {
    "autoconf": struct(
        modes = [MODE_SYSTEM, MODE_NOOP],
        default_mode = MODE_SYSTEM,
        default_version = None,
        known_versions = None,
        wildcards = {},
        binary_versions = None,
        source_versions = None,
        binary_target = None,
        custom_env_var = None,
        custom_alias_name = None,
        custom_launcher = None,
        workspace_bcr_toolchain = None,
        bcr_binary = None,
        toolchain_type = "@rules_foreign_cc//toolchains:autoconf_toolchain",
        noop_env = {
            "AUTOCONF": "{NOOP_BIN}",
            "AUTOHEADER": "{NOOP_BIN}",
            "AUTOM4TE": "{NOOP_BIN}",
        },
    ),
    "automake": struct(
        modes = [MODE_SYSTEM, MODE_NOOP],
        default_mode = MODE_SYSTEM,
        default_version = None,
        known_versions = None,
        wildcards = {},
        binary_versions = None,
        source_versions = None,
        binary_target = None,
        custom_env_var = None,
        custom_alias_name = None,
        custom_launcher = None,
        workspace_bcr_toolchain = None,
        bcr_binary = None,
        toolchain_type = "@rules_foreign_cc//toolchains:automake_toolchain",
        noop_env = {
            "ACLOCAL": "{NOOP_BIN}",
            "AUTOMAKE": "{NOOP_BIN}",
        },
    ),
    "cmake": struct(
        modes = [MODE_BINARY, MODE_CUSTOM, MODE_SOURCE, MODE_SYSTEM, MODE_NOOP],
        default_mode = MODE_BINARY,
        default_version = "3.31.12",
        known_versions = exact_versions(CMAKE_BIN_SRCS, CMAKE_SRC_SRCS),
        wildcards = _wildcards_for(exact_versions(CMAKE_BIN_SRCS, CMAKE_SRC_SRCS)),
        binary_versions = CMAKE_BIN_SRCS,
        source_versions = CMAKE_SRC_SRCS,
        binary_target = "cmake_tool",
        custom_env_var = "CMAKE",
        custom_alias_name = "cmake",
        custom_launcher = None,
        workspace_bcr_toolchain = None,
        bcr_binary = None,
        toolchain_type = "@rules_foreign_cc//toolchains:cmake_toolchain",
        noop_env = {"CMAKE": "{NOOP_BIN}"},
    ),
    "m4": struct(
        modes = [MODE_CUSTOM, MODE_SYSTEM, MODE_NOOP],
        default_mode = MODE_CUSTOM,
        # No versioned mode: rfcc has never shipped an m4 bootstrap, so there
        # is no archive table to pick from and `known_versions` is None. This
        # field is still the @m4 module version the WORKSPACE path fetches, and
        # default_versions_in_sync_test holds it to repositories.bzl.
        default_version = "1.4.21",
        known_versions = None,
        wildcards = {},
        binary_versions = None,
        source_versions = None,
        binary_target = None,
        custom_env_var = "M4",
        custom_alias_name = "m4",
        custom_launcher = None,
        workspace_bcr_toolchain = "@rules_foreign_cc//toolchains/private:built_m4",
        bcr_binary = "@m4//:m4",
        toolchain_type = "@rules_foreign_cc//toolchains:m4_toolchain",
        noop_env = {"M4": "{NOOP_BIN}"},
    ),
    "make": struct(
        modes = [MODE_CUSTOM, MODE_SOURCE, MODE_SYSTEM, MODE_NOOP],
        default_mode = MODE_CUSTOM,
        default_version = "4.4.1",
        known_versions = exact_versions(GNUMAKE_SRCS),
        wildcards = _wildcards_for(exact_versions(GNUMAKE_SRCS)),
        binary_versions = None,
        source_versions = GNUMAKE_SRCS,
        binary_target = None,
        custom_env_var = "MAKE",
        custom_alias_name = "make",
        custom_launcher = None,
        workspace_bcr_toolchain = "@rules_foreign_cc//toolchains/private:built_make",
        bcr_binary = "@make//:make",
        toolchain_type = "@rules_foreign_cc//toolchains:make_toolchain",
        noop_env = {"MAKE": "{NOOP_BIN}"},
    ),
    "meson": struct(
        modes = [MODE_CUSTOM, MODE_SOURCE, MODE_SYSTEM, MODE_NOOP],
        default_mode = MODE_SOURCE,
        # Must match repositories.bzl's DEFAULT_TOOL_VERSIONS (the WORKSPACE
        # default) so the bzlmod and WORKSPACE paths build the same meson;
        # default_versions_in_sync_test enforces it for every tool.
        default_version = "1.10.1",
        known_versions = exact_versions(MESON_SRCS),
        wildcards = _wildcards_for(exact_versions(MESON_SRCS)),
        binary_versions = None,
        source_versions = MESON_SRCS,
        binary_target = None,
        custom_env_var = "MESON",
        custom_alias_name = "meson",
        custom_launcher = None,
        workspace_bcr_toolchain = None,
        bcr_binary = None,
        toolchain_type = "@rules_foreign_cc//toolchains:meson_toolchain",
        noop_env = {"MESON": "{NOOP_BIN}"},
    ),
    "msbuild": struct(
        modes = [MODE_CUSTOM, MODE_SYSTEM, MODE_NOOP],
        default_mode = MODE_SYSTEM,
        default_version = None,
        known_versions = None,
        wildcards = {},
        binary_versions = None,
        source_versions = None,
        binary_target = None,
        custom_env_var = "MSBUILD",
        custom_alias_name = "msbuild",
        custom_launcher = None,
        workspace_bcr_toolchain = None,
        bcr_binary = None,
        # msbuild only exists on Windows; gate the system toolchain on both
        # exec and target (matches the legacy preinstalled_msbuild_toolchain).
        system_exec_compatible_with = ["@platforms//os:windows"],
        system_target_compatible_with = ["@platforms//os:windows"],
        toolchain_type = "@rules_foreign_cc//toolchains:msbuild_toolchain",
        noop_env = {"MSBUILD": "{NOOP_BIN}"},
    ),
    "ninja": struct(
        modes = [MODE_BINARY, MODE_CUSTOM, MODE_SOURCE, MODE_SYSTEM, MODE_NOOP],
        default_mode = MODE_BINARY,
        default_version = "1.13.2",
        known_versions = exact_versions(NINJA_BIN_SRCS, NINJA_SRC_SRCS),
        wildcards = _wildcards_for(exact_versions(NINJA_BIN_SRCS, NINJA_SRC_SRCS)),
        binary_versions = NINJA_BIN_SRCS,
        source_versions = NINJA_SRC_SRCS,
        binary_target = "ninja_tool",
        custom_env_var = "NINJA",
        custom_alias_name = "ninja",
        # meson's and CMake's dependency lookups search PATH for a binary
        # literally named `ninja`, which an arbitrary `target` will not be, so
        # a custom ninja is invoked through the wrapper instead.
        custom_launcher = "@rules_foreign_cc//toolchains/private:ninja_wrapper",
        workspace_bcr_toolchain = "@rules_foreign_cc//toolchains/private:built_ninja",
        bcr_binary = "@ninja//:ninja",
        toolchain_type = "@rules_foreign_cc//toolchains:ninja_toolchain",
        noop_env = {"NINJA": "{NOOP_BIN}"},
    ),
    "nmake": struct(
        modes = [MODE_SYSTEM],
        default_mode = MODE_SYSTEM,
        default_version = None,
        known_versions = None,
        wildcards = {},
        binary_versions = None,
        source_versions = None,
        binary_target = None,
        custom_env_var = None,
        custom_alias_name = None,
        custom_launcher = None,
        workspace_bcr_toolchain = None,
        bcr_binary = None,
        # nmake only exists on Windows; gate the system toolchain so it never
        # resolves on other hosts (matches the legacy
        # preinstalled_nmake_toolchain constraint).
        system_exec_compatible_with = ["@platforms//os:windows"],
        toolchain_type = "@rules_foreign_cc//toolchains:make_toolchain",
        # No noop mode: nmake shares the make_toolchain type and is selected
        # only by explicit toolchain= label (it's Windows-only), so a noop
        # nmake entry would carry no constraints and shadow the real make
        # toolchain on every platform. To no-op the make-family toolchain use
        # tools.make(mode = "noop"), which noops the same type correctly.
        noop_env = {},
    ),
    "pkgconfig": struct(
        modes = [MODE_CUSTOM, MODE_SOURCE, MODE_SYSTEM, MODE_NOOP],
        default_mode = MODE_CUSTOM,
        # The @pkgconf module version WORKSPACE fetches, held to
        # repositories.bzl by default_versions_in_sync_test. Deliberately not a
        # key of `known_versions`: source mode builds freedesktop pkg-config,
        # a different program from pkgconf, and the two do not share a version
        # line. `tools.pkgconfig(mode = "source", version = "3.0.7")` is
        # rejected, which is the honest answer.
        default_version = "3.0.7",
        known_versions = exact_versions(PKGCONFIG_SRCS),
        wildcards = _wildcards_for(exact_versions(PKGCONFIG_SRCS)),
        binary_versions = None,
        source_versions = PKGCONFIG_SRCS,
        binary_target = None,
        custom_env_var = "PKG_CONFIG",
        # `pkg-config`, not `pkgconf`: the framework symlinks the tool into
        # $EXT_BUILD_DEPS/bin under its own basename, and configure scripts and
        # CMake's FindPkgConfig search PATH for the former.
        custom_alias_name = "pkg-config",
        custom_launcher = None,
        workspace_bcr_toolchain = "@rules_foreign_cc//toolchains/private:built_pkgconfig",
        bcr_binary = "@pkgconf//:pkg-config",
        toolchain_type = "@rules_foreign_cc//toolchains:pkgconfig_toolchain",
        # Only the binary var, like every other tool: noop sets PKG_CONFIG to
        # the failing sentinel and stops there. A noop PKG_CONFIG_PATH buys
        # nothing -- `false` never reads its environment, and the framework
        # appends real dep .pc dirs regardless of the seed, so the value can't
        # mean "search nothing."
        noop_env = {
            "PKG_CONFIG": "{NOOP_BIN}",
        },
    ),
}

ALL_TOOLS = sorted(TOOL_SPECS.keys())

# Tools that have no source/binary mode and no version (system or noop only).
VERSIONLESS_TOOLS = [
    name
    for name, spec in TOOL_SPECS.items()
    if spec.default_version == None
]

# Tools with a source mode. Each is materialized as an @<tool>_src_<version>
# spoke: source mode means "build it from an archive rfcc hashes", with no
# exceptions.
SOURCE_TOOLS = sorted([
    name
    for name, spec in TOOL_SPECS.items()
    if MODE_SOURCE in spec.modes
])

# Tools whose binary comes from a registry module (@m4, @make, @ninja,
# @pkgconf) rather than from an archive rfcc builds. Only these specs have a
# non-None `bcr_binary` and `workspace_bcr_toolchain`.
#
# This is *not* the complement of SOURCE_TOOLS: make, ninja and pkgconfig are
# in both -- they bootstrap from source under `mode = "source"` and use the
# registry module under `mode = "custom"` -- while m4 is registry-only.
BCR_BACKED_TOOLS = [
    name
    for name in ALL_TOOLS
    if TOOL_SPECS[name].bcr_binary != None
]

def get_spec(tool):
    """Returns the struct for a tool, or fails if the tool is unknown."""
    if tool not in TOOL_SPECS:
        fail("Unknown tool \"{}\". Known tools: {}".format(tool, ALL_TOOLS))
    return TOOL_SPECS[tool]

def versions_for_mode(spec, mode):
    """Return the version table backing `mode`, or None if it isn't versioned.

    Only binary and source are versioned. custom takes a target instead, and
    system and noop take neither.

    Args:
        spec: a tool struct from `TOOL_SPECS`.
        mode: one of `ALL_MODES`.

    Returns:
        A ``{version: spec}`` dict, or None.
    """
    if mode == MODE_BINARY:
        return spec.binary_versions
    if mode == MODE_SOURCE:
        return spec.source_versions
    return None
