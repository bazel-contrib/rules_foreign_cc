"""Per-tool metadata: modes, default versions, known versions, noop env vars.

Single source of truth shared by foreign_cc/extensions.bzl and
toolchains/private/noop_toolchains.bzl. Edit this module when bumping default
versions, adding tools, or adjusting noop env vars.

`known_versions` is a list-or-None of versions accepted in
`tools.<tool>(version = ...)`. None means "this tool is
versionless (system/noop only)." For tools with a binary mode the list is
the union of binary-table keys and source-table keys, because the mode a
bare `version =` resolves to depends on the tool's ladder. The union is only
an outer bound: `tag_error` re-checks the version against the resolved mode's
own table, so ninja -- whose prebuilt releases and registry modules overlap
without coinciding -- rejects `mode = "binary", version = "1.13.1"`.
"""

# The version dicts under //toolchains/private declare a top-of-file
# `visibility([...])` that explicitly allows //foreign_cc/private to load
# them; buildifier's bzl-visibility heuristic only inspects path layout
# and doesn't honor the directive. Suppress the lint here.
# buildifier: disable=bzl-visibility
load("//toolchains/private:bcr_modules.bzl", "BCR_TOOLS")

# buildifier: disable=bzl-visibility
load("//toolchains/private:cmake_versions.bzl", "CMAKE_BIN_SRCS", "CMAKE_SRC_SRCS")

# buildifier: disable=bzl-visibility
load("//toolchains/private:meson_versions.bzl", "MESON_SRCS")

# buildifier: disable=bzl-visibility
load("//toolchains/private:ninja_versions.bzl", "NINJA_BIN_SRCS")

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

# `BCR_TOOLS[<module>]` is read directly by the source specs below. Unlike the
# other source tables only its keys matter, since one `@m4` / `@make` /
# `@ninja` / `@pkgconf` exists per build -- see the `source_target` note below.
# rfcc's `pkgconfig` tool is the `pkgconf` module.

# Mode constants. Use these strings everywhere.
MODE_BINARY = "binary"
MODE_SOURCE = "source"
MODE_SYSTEM = "system"
MODE_NOOP = "noop"

ALL_MODES = [MODE_BINARY, MODE_SOURCE, MODE_SYSTEM, MODE_NOOP]

# Per-tool metadata. Order of LADDER entries is the auto-priority order
# used when a root tag does not specify `mode`.
#
# `source_target` is where a source-mode toolchain points. None (the common
# case) means rfcc mints an @<tool>_src_<version> spoke and derives the label
# from it. A label means the tool comes from a registry module rfcc doesn't own
# (@m4, @make, @ninja, @pkgconf), so the target is static and there is nothing
# for the planner to fetch or alias. Those tools still offer a version matrix,
# selected where the repo is declared -- a `bazel_dep` under bzlmod,
# `bcr_repos` under WORKSPACE -- rather than in the label.
TOOL_SPECS = {
    "autoconf": struct(
        modes = [MODE_SYSTEM, MODE_NOOP],
        ladder = [MODE_SYSTEM],
        default_version = None,
        known_versions = None,
        wildcards = {},
        binary_versions = None,
        source_versions = None,
        binary_target = None,
        source_target = None,
        toolchain_type = "@rules_foreign_cc//toolchains:autoconf_toolchain",
        noop_env = {
            "AUTOCONF": "{NOOP_BIN}",
            "AUTOHEADER": "{NOOP_BIN}",
            "AUTOM4TE": "{NOOP_BIN}",
        },
    ),
    "automake": struct(
        modes = [MODE_SYSTEM, MODE_NOOP],
        ladder = [MODE_SYSTEM],
        default_version = None,
        known_versions = None,
        wildcards = {},
        binary_versions = None,
        source_versions = None,
        binary_target = None,
        source_target = None,
        toolchain_type = "@rules_foreign_cc//toolchains:automake_toolchain",
        noop_env = {
            "ACLOCAL": "{NOOP_BIN}",
            "AUTOMAKE": "{NOOP_BIN}",
        },
    ),
    "cmake": struct(
        modes = [MODE_BINARY, MODE_SOURCE, MODE_SYSTEM, MODE_NOOP],
        ladder = [MODE_BINARY, MODE_SOURCE, MODE_SYSTEM],
        default_version = "3.31.12",
        known_versions = exact_versions(CMAKE_BIN_SRCS, CMAKE_SRC_SRCS),
        wildcards = _wildcards_for(exact_versions(CMAKE_BIN_SRCS, CMAKE_SRC_SRCS)),
        binary_versions = CMAKE_BIN_SRCS,
        source_versions = CMAKE_SRC_SRCS,
        binary_target = "cmake_tool",
        source_target = None,
        toolchain_type = "@rules_foreign_cc//toolchains:cmake_toolchain",
        noop_env = {"CMAKE": "{NOOP_BIN}"},
    ),
    "m4": struct(
        modes = [MODE_SOURCE, MODE_SYSTEM, MODE_NOOP],
        ladder = [MODE_SOURCE, MODE_SYSTEM],
        default_version = "1.4.21",
        known_versions = exact_versions(BCR_TOOLS["m4"]),
        wildcards = _wildcards_for(exact_versions(BCR_TOOLS["m4"])),
        binary_versions = None,
        source_versions = BCR_TOOLS["m4"],
        binary_target = None,
        source_target = "@rules_foreign_cc//toolchains/private:built_m4",
        bcr_binary = "@m4//:m4",
        toolchain_type = "@rules_foreign_cc//toolchains:m4_toolchain",
        noop_env = {"M4": "{NOOP_BIN}"},
    ),
    "make": struct(
        modes = [MODE_SOURCE, MODE_SYSTEM, MODE_NOOP],
        ladder = [MODE_SOURCE, MODE_SYSTEM],
        default_version = "4.4.1",
        known_versions = exact_versions(BCR_TOOLS["make"]),
        wildcards = _wildcards_for(exact_versions(BCR_TOOLS["make"])),
        binary_versions = None,
        source_versions = BCR_TOOLS["make"],
        binary_target = None,
        source_target = "@rules_foreign_cc//toolchains/private:built_make",
        bcr_binary = "@make//:make",
        toolchain_type = "@rules_foreign_cc//toolchains:make_toolchain",
        noop_env = {"MAKE": "{NOOP_BIN}"},
    ),
    "meson": struct(
        modes = [MODE_SOURCE, MODE_SYSTEM, MODE_NOOP],
        ladder = [MODE_SOURCE, MODE_SYSTEM],
        # Must match repositories.bzl's DEFAULT_TOOL_VERSIONS (the WORKSPACE
        # default) so the bzlmod and WORKSPACE paths build the same meson;
        # default_versions_in_sync_test enforces it for every tool.
        default_version = "1.10.1",
        known_versions = exact_versions(MESON_SRCS),
        wildcards = _wildcards_for(exact_versions(MESON_SRCS)),
        binary_versions = None,
        source_versions = MESON_SRCS,
        binary_target = None,
        source_target = None,
        toolchain_type = "@rules_foreign_cc//toolchains:meson_toolchain",
        noop_env = {"MESON": "{NOOP_BIN}"},
    ),
    "msbuild": struct(
        modes = [MODE_SYSTEM, MODE_NOOP],
        ladder = [MODE_SYSTEM],
        default_version = None,
        known_versions = None,
        wildcards = {},
        binary_versions = None,
        source_versions = None,
        binary_target = None,
        source_target = None,
        # msbuild only exists on Windows; gate the system toolchain on both
        # exec and target (matches the legacy preinstalled_msbuild_toolchain).
        system_exec_compatible_with = ["@platforms//os:windows"],
        system_target_compatible_with = ["@platforms//os:windows"],
        toolchain_type = "@rules_foreign_cc//toolchains:msbuild_toolchain",
        noop_env = {"MSBUILD": "{NOOP_BIN}"},
    ),
    "ninja": struct(
        modes = [MODE_BINARY, MODE_SOURCE, MODE_SYSTEM, MODE_NOOP],
        ladder = [MODE_BINARY, MODE_SOURCE, MODE_SYSTEM],
        default_version = "1.13.2",
        known_versions = exact_versions(NINJA_BIN_SRCS, BCR_TOOLS["ninja"]),
        wildcards = _wildcards_for(exact_versions(NINJA_BIN_SRCS, BCR_TOOLS["ninja"])),
        binary_versions = NINJA_BIN_SRCS,
        source_versions = BCR_TOOLS["ninja"],
        binary_target = "ninja_tool",
        source_target = "@rules_foreign_cc//toolchains/private:built_ninja",
        bcr_binary = "@ninja//:ninja",
        toolchain_type = "@rules_foreign_cc//toolchains:ninja_toolchain",
        noop_env = {"NINJA": "{NOOP_BIN}"},
    ),
    "nmake": struct(
        modes = [MODE_SYSTEM],
        ladder = [MODE_SYSTEM],
        default_version = None,
        known_versions = None,
        wildcards = {},
        binary_versions = None,
        source_versions = None,
        binary_target = None,
        source_target = None,
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
        modes = [MODE_SOURCE, MODE_SYSTEM, MODE_NOOP],
        ladder = [MODE_SOURCE, MODE_SYSTEM],
        default_version = "3.0.7",
        known_versions = exact_versions(BCR_TOOLS["pkgconf"]),
        wildcards = _wildcards_for(exact_versions(BCR_TOOLS["pkgconf"])),
        binary_versions = None,
        source_versions = BCR_TOOLS["pkgconf"],
        binary_target = None,
        source_target = "@rules_foreign_cc//toolchains/private:built_pkgconfig",
        # `:pkg-config`, not the module's `:pkgconf`: the two are the same
        # binary, but only the former is named what a configure script or
        # CMake's FindPkgConfig looks for on PATH, and the framework symlinks
        # `path` into $EXT_BUILD_DEPS/bin under its own basename.
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

SOURCE_TOOLS = sorted([
    name
    for name, spec in TOOL_SPECS.items()
    if MODE_SOURCE in spec.modes
])

# Source-mode tools rfcc materializes as an @<tool>_src_<version> spoke.
# Callers that fetch spokes or publish spoke aliases want this, not
# SOURCE_TOOLS. Identical under both dependency models.
SPOKE_SOURCE_TOOLS = [
    name
    for name in SOURCE_TOOLS
    if TOOL_SPECS[name].source_target == None
]

# The exact complement: tools built by a registry module. Only these specs
# carry `bcr_binary`, so it is safe to read for every member and only for
# members. Both halves come from the same `source_target` test, so another
# registry-backed tool joins every loop without a literal to update.
BCR_SOURCE_TOOLS = [
    name
    for name in SOURCE_TOOLS
    if TOOL_SPECS[name].source_target != None
]

def get_spec(tool):
    """Returns the struct for a tool, or fails if the tool is unknown."""
    if tool not in TOOL_SPECS:
        fail("Unknown tool \"{}\". Known tools: {}".format(tool, ALL_TOOLS))
    return TOOL_SPECS[tool]

def versions_for_mode(spec, mode):
    """Return the version table backing `mode`, or None if it isn't versioned.

    system and noop take no version, so only binary and source have a table.

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
