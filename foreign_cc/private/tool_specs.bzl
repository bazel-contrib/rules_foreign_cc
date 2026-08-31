"""Per-tool metadata: modes, default versions, known versions, noop env vars.

Single source of truth shared by foreign_cc/extensions.bzl and
toolchains/private/noop_toolchains.bzl. Edit this module when bumping default
versions, adding tools, or adjusting noop env vars.

`known_versions` is a list-or-None of versions accepted in
`tools.<tool>(version = ...)`. None means "this tool is
versionless (system/noop only)." For tools with a binary mode the list is
the union of binary-table keys and source-table keys (so a version that
exists in only one of the two is still accepted; the planner picks the
mode based on the tool's ladder and what's actually available).
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

def _is_exact(version):
    """True for an exact version key (not a `major.minor.x` wildcard).

    Accepts both `major.minor.patch` and bare `major.minor` keys: make ships
    two-component upstream releases (`4.3`, `4.4`) alongside `4.4.1`, and all
    are real, fetchable versions. Only the `.x` wildcard alias keys are
    excluded.
    """
    parts = version.split(".")
    return len(parts) >= 2 and parts[-1] != "x"

def _version_tuple(version):
    """Numeric tuple for ordering version keys; shorter keys sort lower.

    `4.4` -> (4, 4) sorts below `4.4.1` -> (4, 4, 1), so the latest patch in a
    minor series wins in `_wildcards_for`.
    """
    return tuple([int(p) for p in version.split(".")])

def _exact_versions(*dicts):
    """Sorted union of the exact-patch keys across the given version dicts.

    The source dicts (e.g. CMAKE_SRC_SRCS) carry duplicate `a.b.x` wildcard
    keys alongside their exact patches; those are filtered out here so
    `known_versions` is exact-only. Wildcards are handled separately via
    `_wildcards_for`.
    """
    seen = {}
    for d in dicts:
        for k in d.keys():
            if _is_exact(k):
                seen[k] = True
    return sorted(seen.keys())

def _assert_symmetric(tool, bin_dict, src_dict):
    """Fail if a tool's binary and source tables cover different versions.

    A tool that offers both `mode = "binary"` and `mode = "source"` must
    accept the same version in either mode -- otherwise
    `tools.<tool>(mode = "source", version = V)` could pass validation
    (which checks the bin+src union) and then fail late when the source
    archive for V doesn't exist. Keeping the tables in lockstep means the
    unified `version =` surface behaves identically across modes. The
    generator enforces this (ninja's NINJA_MINORS is capped to the
    source-build range); this guard catches a hand-edit that breaks it.
    """
    bin_versions = [k for k in bin_dict.keys() if _is_exact(k)]
    src_versions = [k for k in src_dict.keys() if _is_exact(k)]
    if sorted(bin_versions) != sorted(src_versions):
        only_bin = sorted([v for v in bin_versions if v not in src_versions])
        only_src = sorted([v for v in src_versions if v not in bin_versions])
        fail(("tool_specs: {} binary and source version tables must match, " +
              "but binary-only={} source-only={}. A tool with both modes must " +
              "offer the same versions in each.").format(tool, only_bin, only_src))

def _wildcards_for(versions):
    """Map ``{"a.b.x": "a.b.c"}`` from a list of exact versions.

    Each `major.minor.x` resolves to the latest exact version in that series.
    cmake/ninja ship one patch per minor so there's never a contest; make
    ships both `4.4` and `4.4.1`, and `4.4.x` must resolve to `4.4.1` (the
    latest), matching the spelling the old built_toolchains.bzl accepted.
    """
    out = {}
    for version in versions:
        parts = version.split(".")
        key = "{}.{}.x".format(parts[0], parts[1])
        if key not in out or _version_tuple(version) > _version_tuple(out[key]):
            out[key] = version
    return out

# Tools with both binary and source modes must offer identical version sets
# so `tools.<tool>(version = ...)` behaves the same in either mode.
_assert_symmetric("cmake", CMAKE_BIN_SRCS, CMAKE_SRC_SRCS)
_assert_symmetric("ninja", NINJA_BIN_SRCS, NINJA_SRC_SRCS)

# Mode constants. Use these strings everywhere.
MODE_BINARY = "binary"
MODE_SOURCE = "source"
MODE_SYSTEM = "system"
MODE_NOOP = "noop"

ALL_MODES = [MODE_BINARY, MODE_SOURCE, MODE_SYSTEM, MODE_NOOP]

# Per-tool metadata. Order of LADDER entries is the auto-priority order
# used when a root tag does not specify `mode`.
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
        known_versions = _exact_versions(CMAKE_BIN_SRCS, CMAKE_SRC_SRCS),
        wildcards = _wildcards_for(_exact_versions(CMAKE_BIN_SRCS, CMAKE_SRC_SRCS)),
        binary_versions = CMAKE_BIN_SRCS,
        source_versions = CMAKE_SRC_SRCS,
        binary_target = "cmake_tool",
        toolchain_type = "@rules_foreign_cc//toolchains:cmake_toolchain",
        noop_env = {"CMAKE": "{NOOP_BIN}"},
    ),
    "m4": struct(
        modes = [MODE_SYSTEM, MODE_NOOP],
        ladder = [MODE_SYSTEM],
        default_version = None,
        known_versions = None,
        wildcards = {},
        binary_versions = None,
        source_versions = None,
        binary_target = None,
        toolchain_type = "@rules_foreign_cc//toolchains:m4_toolchain",
        noop_env = {"M4": "{NOOP_BIN}"},
    ),
    "make": struct(
        modes = [MODE_SOURCE, MODE_SYSTEM, MODE_NOOP],
        ladder = [MODE_SOURCE, MODE_SYSTEM],
        default_version = "4.4.1",
        known_versions = _exact_versions(GNUMAKE_SRCS),
        wildcards = _wildcards_for(_exact_versions(GNUMAKE_SRCS)),
        binary_versions = None,
        source_versions = GNUMAKE_SRCS,
        binary_target = None,
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
        known_versions = _exact_versions(MESON_SRCS),
        wildcards = _wildcards_for(_exact_versions(MESON_SRCS)),
        binary_versions = None,
        source_versions = MESON_SRCS,
        binary_target = None,
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
        known_versions = _exact_versions(NINJA_BIN_SRCS, NINJA_SRC_SRCS),
        wildcards = _wildcards_for(_exact_versions(NINJA_BIN_SRCS, NINJA_SRC_SRCS)),
        binary_versions = NINJA_BIN_SRCS,
        source_versions = NINJA_SRC_SRCS,
        binary_target = "ninja_tool",
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
        default_version = "0.29.2",
        known_versions = _exact_versions(PKGCONFIG_SRCS),
        wildcards = _wildcards_for(_exact_versions(PKGCONFIG_SRCS)),
        binary_versions = None,
        source_versions = PKGCONFIG_SRCS,
        binary_target = None,
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

def get_spec(tool):
    """Returns the struct for a tool, or fails if the tool is unknown."""
    if tool not in TOOL_SPECS:
        fail("Unknown tool \"{}\". Known tools: {}".format(tool, ALL_TOOLS))
    return TOOL_SPECS[tool]
