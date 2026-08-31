#!/usr/bin/env python3
"""Generator for rules_foreign_cc per-tool version data.

This is the single source of truth for every toolchain's per-version data.
It emits one ``*_versions.bzl`` dict file per tool under ``toolchains/private/``.
The spoke helpers (``binary_spokes.bzl``, ``source_spokes.bzl``) and
``toolchains/prebuilt_toolchains.bzl`` are hand-maintained and NOT written here;
they read the generated dicts.

The version SET each tool ships is configured in the USER CONFIGURATION block
below -- the only part you edit to add or drop a version. Everything after the
machinery divider derives data from it (fetching, hashing, rendering).

Run from the repo root:

    python3 toolchains/prebuilt_toolchains.py
"""

import hashlib
import json
import os
import re
import sys
import urllib.request
from pathlib import Path

# ===========================================================================
# USER CONFIGURATION
#
# This is the only block you edit to add or drop a tool version. Everything
# below the machinery divider derives from these declarations.
# ===========================================================================

# --- CMake -----------------------------------------------------------------
#
# Minor series to support; the latest patch within each is auto-discovered and
# used for BOTH the prebuilt binary and the from-source build, so the two modes
# always accept the same versions.
CMAKE_MINORS = (
    "4.0",
    "3.31",
    "3.30",
    "3.29",
    "3.28",
    "3.27",
    "3.26",
    "3.25",
    "3.24",
    "3.23",
    "3.22",
    "3.21",
    "3.20",
    "3.19",
)

CMAKE_DIR_URL_TEMPLATE = "https://cmake.org/files/v{minor}/"
CMAKE_SHA256_URL_TEMPLATE = "https://cmake.org/files/v{minor}/cmake-{full}-SHA-256.txt"
CMAKE_URL_TEMPLATE = "https://github.com/Kitware/CMake/releases/download/v{full}/{file}"

# Maps the upstream archive's platform-tag substring to the canonical
# (os, arch) pair used as a key in CMAKE_BIN_SRCS, and to the platform
# constraints emitted in the dict's ``constraints`` field.
CMAKE_TARGETS = {
    "Darwin-x86_64": {
        "os_arch": ("macos", "x86_64"),
        "constraints": [
            "@platforms//cpu:x86_64",
            "@platforms//os:macos",
        ],
    },
    "linux-aarch64": {
        "os_arch": ("linux", "aarch64"),
        "constraints": [
            "@platforms//cpu:aarch64",
            "@platforms//os:linux",
        ],
    },
    "linux-x86_64": {
        "os_arch": ("linux", "x86_64"),
        "constraints": [
            "@platforms//cpu:x86_64",
            "@platforms//os:linux",
        ],
    },
    "Linux-aarch64": {
        "os_arch": ("linux", "aarch64"),
        "constraints": [
            "@platforms//cpu:aarch64",
            "@platforms//os:linux",
        ],
    },
    "Linux-x86_64": {
        "os_arch": ("linux", "x86_64"),
        "constraints": [
            "@platforms//cpu:x86_64",
            "@platforms//os:linux",
        ],
    },
    "macos-universal": {
        "os_arch": ("macos", "universal"),
        "constraints": [
            "@platforms//os:macos",
        ],
    },
    "windows-i386": {
        "os_arch": ("windows", "x86_32"),
        "constraints": [
            "@platforms//cpu:x86_32",
            "@platforms//os:windows",
        ],
    },
    "windows-x86_64": {
        "os_arch": ("windows", "x86_64"),
        "constraints": [
            "@platforms//cpu:x86_64",
            "@platforms//os:windows",
        ],
    },
    "win32-x86": {
        "os_arch": ("windows", "x86_32"),
        "constraints": [
            "@platforms//cpu:x86_32",
            "@platforms//os:windows",
        ],
    },
    "win64-x64": {
        "os_arch": ("windows", "x86_64"),
        "constraints": [
            "@platforms//cpu:x86_64",
            "@platforms//os:windows",
        ],
    },
}

# --- Ninja -----------------------------------------------------------------
#
# Minor series to support; the latest patch within each is auto-discovered and
# used for BOTH the prebuilt binary and the from-source build (see
# NINJA_SRC_PATCHES), so the two modes always accept the same versions. Capped
# at 1.10 because that is the oldest series rules_foreign_cc ships a source
# build for.
NINJA_MINORS = (
    "1.13",
    "1.12",
    "1.11",
    "1.10",
)

NINJA_RELEASES_URL = (
    "https://api.github.com/repos/ninja-build/ninja/releases?per_page=100"
)
NINJA_URL_TEMPLATE = (
    "https://github.com/ninja-build/ninja/releases/download/v{full}/ninja-{target}.zip"
)
# Source-mode archive (bazel mirror first, upstream github fallback); the
# sha256 is hashed at generation time. A version with no mirror copy yet
# 404s past the mirror to github, at both hash time and build time.
NINJA_SRC_URL_TEMPLATE = (
    "https://mirror.bazel.build/github.com/ninja-build/ninja/archive/v{version}.tar.gz"
)
NINJA_SRC_URL_FALLBACK = (
    "https://github.com/ninja-build/ninja/archive/v{version}.tar.gz"
)
# Per-version source patch overrides. The source version SET is derived from
# NINJA_MINORS (same exact patches as the binaries); this map only attaches
# patch labels to specific versions. Ninja needs none today, so it's empty --
# add an entry keyed by exact version (e.g. "1.13.2": [label]) if a future
# version needs one.
NINJA_SRC_PATCHES = {}

NINJA_TARGETS = {
    "linux": {
        "os_arch": ("linux", "x86_64"),
        "constraints": [
            "@platforms//cpu:x86_64",
            "@platforms//os:linux",
        ],
    },
    "linux-aarch64": {
        "os_arch": ("linux", "aarch64"),
        "constraints": [
            "@platforms//cpu:aarch64",
            "@platforms//os:linux",
        ],
    },
    "mac": {
        "os_arch": ("macos", "x86_64"),
        "constraints": [
            "@platforms//cpu:x86_64",
            "@platforms//os:macos",
        ],
    },
    "mac_aarch64": {
        "os_arch": ("macos", "aarch64"),
        "constraints": [
            "@platforms//cpu:aarch64",
            "@platforms//os:macos",
        ],
    },
    "win": {
        "os_arch": ("windows", "x86_64"),
        "constraints": [
            "@platforms//cpu:x86_64",
            "@platforms//os:windows",
        ],
    },
}

# --- Make (source-only) ----------------------------------------------------
#
# {version: [patch labels]}. The sha256 is hashed at generation time. make's
# reproducible-bootstrap patch targets per-version bootstrap files, so each
# version names its own; a version with no divergence can use [].
MAKE_URL_TEMPLATE = (
    "https://mirror.bazel.build/ftpmirror.gnu.org/gnu/make/make-{version}.tar.gz"
)
MAKE_URL_FALLBACK = "http://ftpmirror.gnu.org/gnu/make/make-{version}.tar.gz"
MAKE_VERSIONS = {
    "4.4.1": ["//toolchains/patches:make-4.4.1-reproducible-bootstrap.patch"],
    "4.4": ["//toolchains/patches:make-4.4-reproducible-bootstrap.patch"],
    "4.3": ["//toolchains/patches:make-4.3-reproducible-bootstrap.patch"],
}

# --- Meson (source-only) ---------------------------------------------------
#
# {version: [patch labels]}. The sha256 is hashed at generation time.
MESON_URL_TEMPLATE = "https://mirror.bazel.build/github.com/mesonbuild/meson/releases/download/{version}/meson-{version}.tar.gz"
MESON_URL_FALLBACK = "https://github.com/mesonbuild/meson/releases/download/{version}/meson-{version}.tar.gz"
MESON_VERSIONS = {
    "1.10.1": [],
    "1.5.1": [],
    "1.1.1": [],
    "0.63.0": [],
}

# --- pkg-config (source-only) ----------------------------------------------
#
# {version: [patch labels]}. The sha256 is hashed at generation time.
PKGCONFIG_URL_TEMPLATE = "https://mirror.bazel.build/pkgconfig.freedesktop.org/releases/pkg-config-{version}.tar.gz"
PKGCONFIG_URL_FALLBACK = (
    "https://pkgconfig.freedesktop.org/releases/pkg-config-{version}.tar.gz"
)
PKGCONFIG_VERSIONS = {
    "0.29.2": [
        "//toolchains/patches:pkgconfig-detectenv.patch",
        "//toolchains/patches:pkgconfig-makefile-vc.patch",
        "//toolchains/patches:pkgconfig-builtin-glib-int-conversion.patch",
    ],
}

# ===========================================================================
# MACHINERY
#
# Everything below derives data from the configuration above: fetching latest
# patches, hashing archives, and rendering the generated ``*_versions.bzl``
# files. You shouldn't need to edit this to add or drop a version.
# ===========================================================================

# Optional sha256 cache: speed up reruns. Set PREBUILT_TOOLCHAINS_SHA_CACHE
# to a JSON file path to enable. The cache file is a developer convenience and
# is intentionally not committed; the dict files are the durable artifact.
_SHA_CACHE_PATH = (
    Path(os.environ["PREBUILT_TOOLCHAINS_SHA_CACHE"])
    if "PREBUILT_TOOLCHAINS_SHA_CACHE" in os.environ
    else None
)


def _load_sha_cache():
    if _SHA_CACHE_PATH is None:
        return {}
    try:
        return json.loads(_SHA_CACHE_PATH.read_text())
    except (FileNotFoundError, ValueError):
        return {}


def _save_sha_cache(cache):
    if _SHA_CACHE_PATH is None:
        return
    _SHA_CACHE_PATH.write_text(json.dumps(cache, indent=2, sort_keys=True))


_SHA_CACHE = _load_sha_cache()


def _log(msg):
    """Print a progress line to stderr immediately (unbuffered)."""
    print(msg, file=sys.stderr, flush=True)


def _fetch(url):
    return urllib.request.urlopen(url).read().decode("utf-8", "replace")


# Cap on archives we'll hash, as a guard against pointing this at something
# huge by mistake. The prebuilt archives are tiny (ninja zips ~600 KiB, cmake
# tarballs a few tens of MiB), so anything past this is almost certainly wrong.
_MAX_HASH_BYTES = 100 * 1024 * 1024


def _sha256_of(url):
    """Stream `url` and return its hex sha256.

    Counts *returned* bytes (not requested), and raises rather than silently
    hashing a truncated stream if the archive exceeds _MAX_HASH_BYTES -- a
    truncated hash would be wrong and non-reproducible, baking a bad sha256
    into the generated data.
    """
    remote = urllib.request.urlopen(url)
    total = 0
    h = hashlib.sha256()
    while True:
        data = remote.read(65536)
        if not data:
            break
        total += len(data)
        if total > _MAX_HASH_BYTES:
            raise RuntimeError(
                "{} exceeds the {}-byte hashing cap; refusing to bake a "
                "truncated sha256. Raise _MAX_HASH_BYTES if this archive is "
                "legitimately that large.".format(url, _MAX_HASH_BYTES)
            )
        h.update(data)
    return h.hexdigest()


def _sha256_of_first(urls):
    """Return the sha256 of the first reachable url, trying them in order.

    URLs are listed mirror-first; an unpopulated mirror (e.g. for a freshly
    added version) 404s and we fall through to upstream. The same archive
    hashes to the same digest regardless of which url serves it, so any
    already-cached url in the list is a hit. Results are cached per url.
    """
    for url in urls:
        if url in _SHA_CACHE:
            return _SHA_CACHE[url]
    last_err = None
    for url in urls:
        try:
            sha = _sha256_of(url)
        except Exception as err:  # noqa: BLE001 - try the next mirror
            last_err = err
            _log("  fetch failed ({}): {}".format(url, err))
            continue
        _SHA_CACHE[url] = sha
        return sha
    raise RuntimeError(
        "could not fetch any url to hash: {} (last error: {})".format(urls, last_err)
    )


def latest_cmake_patch(minor):
    """Return the highest "<minor>.<patch>" cmake release.

    Reads the per-minor directory index once and takes the max patch, rather
    than probing each patch in turn.
    """
    listing = _fetch(CMAKE_DIR_URL_TEMPLATE.format(minor=minor))
    patches = {
        int(m)
        for m in re.findall(rf"cmake-{re.escape(minor)}\.(\d+)\.tar\.gz", listing)
    }
    if not patches:
        raise RuntimeError(f"no cmake patch found for series {minor}")
    latest = f"{minor}.{max(patches)}"
    _log(f"  cmake {minor}: patches {sorted(patches)} -> {latest}")
    return latest


def latest_ninja_patches(minors):
    """Return {minor: "<minor>.<patch>"} for each requested ninja minor.

    The GitHub releases API lists every tag in one response, so all minors
    are resolved from a single request.
    """
    releases = json.loads(_fetch(NINJA_RELEASES_URL))
    tags = [r["tag_name"].lstrip("v") for r in releases]

    result = {}
    for minor in minors:
        patches = set()
        for tag in tags:
            m = re.fullmatch(rf"{re.escape(minor)}\.(\d+)", tag)
            if m:
                patches.add(int(m.group(1)))
        if not patches:
            raise RuntimeError(f"no ninja patch found for series {minor}")
        result[minor] = f"{minor}.{max(patches)}"
        _log(f"  ninja {minor}: patches {sorted(patches)} -> {result[minor]}")
    return result


# ---------------------------------------------------------------------------
# Generated-file rendering
# ---------------------------------------------------------------------------

# Visibility header emitted on every generated ``*_versions.bzl``.
GEN_HEADER = (
    '"""@generated by toolchains/prebuilt_toolchains.py - do not edit."""\n\n'
    "visibility([\n"
    '    "//foreign_cc",\n'
    '    "//foreign_cc/private",\n'
    '    "//toolchains",\n'
    "])\n\n"
)


def _q(s):
    """Render a Starlark string literal with double quotes (buildifier style)."""
    return json.dumps(s, ensure_ascii=False)


def _format_patches(patches):
    if not patches:
        return "[]"
    return "[" + ", ".join("Label({})".format(_q(p)) for p in patches) + "]"


def _version_key(version):
    """Sort key for a dotted version, tolerant of 2- vs 3-component strings.

    "4.4" sorts below "4.4.1" (missing components count as 0), so the latest
    patch in a minor series wins when picking a wildcard target.
    """
    return tuple(int(p) for p in version.split("."))


def hashed_source_versions(tool, versions, url_template, fallback_template):
    """Expand a ``{version: [patch labels]}`` map into ``{version: meta}``.

    Each entry gets explicit ``urls`` (bazel mirror first, upstream fallback)
    and a ``sha256`` hashed from the first reachable url at generation time, so
    adding a version is a one-line edit -- no hand-pasted digest. ``patches``
    is carried through verbatim.
    """
    out = {}
    for version, patches in versions.items():
        urls = [url_template.format(version=version)]
        if fallback_template:
            urls.append(fallback_template.format(version=version))
        _log("hashing {} {}".format(tool, version))
        out[version] = {
            "urls": urls,
            "sha256": _sha256_of_first(urls),
            "patches": list(patches),
        }
    return out


def add_source_wildcards(versions, url_template, fallback_template, prefix_template):
    """Return a copy of a source-version dict with `<major>.<minor>.x` aliases.

    For every minor series present, add an alias keyed `<major>.<minor>.x`
    that points at the latest patch in that series. The alias carries an
    explicit `urls` + `strip_prefix` resolved from the exact patch, so the
    archive still unpacks from (e.g.) `make-4.4.1`, not a bogus `make-4.4.x`.
    The hand-written `built_toolchains.bzl` accepted these spellings, so this
    keeps the WORKSPACE source-mode wildcard contract intact across tools.

    cmake builds its own `.x` aliases in get_cmake_definitions (its entries
    carry explicit per-platform `urls`); this helper covers the source-only
    tools whose entries derive their URL from the version key.
    """
    latest_by_minor = {}
    for version in versions:
        major, minor = version.split(".")[:2]
        series = "{}.{}".format(major, minor)
        if series not in latest_by_minor or _version_key(version) > _version_key(
            latest_by_minor[series]
        ):
            latest_by_minor[series] = version

    out = dict(versions)
    for series, version in latest_by_minor.items():
        meta = dict(versions[version])
        if "urls" not in meta:
            urls = [url_template.format(version=version)]
            if fallback_template:
                urls.append(fallback_template.format(version=version))
            meta["urls"] = urls
        meta.setdefault("strip_prefix", prefix_template.format(version=version))
        out["{}.x".format(series)] = meta
    return out


def render_source_dict(
    varname, url_template, fallback_template, versions, prefix_template
):
    """Render a ``{version: struct(...)}`` Starlark literal for source-mode tools.

    Returns a Starlark fragment (without the visibility header). Versions are
    emitted in lexicographic order so buildifier's ``unsorted-dict-items``
    warning stays quiet on the generated file.
    """
    if isinstance(versions, dict):
        items = sorted(versions.items())
    else:
        items = sorted(list(versions))

    entries = []
    for version, meta in items:
        if "urls" in meta:
            urls = list(meta["urls"])
        else:
            urls = [url_template.format(version=version)]
            if fallback_template:
                urls.append(fallback_template.format(version=version))
        # An explicit strip_prefix wins over the key-derived one. This matters
        # for `.x` wildcard alias keys (e.g. cmake "3.19.x"), whose archive
        # still unpacks to the exact-patch directory ("cmake-3.19.8"), so the
        # alias must reuse its sibling's prefix rather than "cmake-3.19.x".
        if meta.get("strip_prefix"):
            prefix = meta["strip_prefix"]
        else:
            prefix = prefix_template.format(version=version)
        urls_lines = (
            "[\n"
            + "".join("            {},\n".format(_q(u)) for u in urls)
            + "        ]"
        )
        entries.append(
            "    {ver}: struct(\n"
            "        urls = {urls},\n"
            "        strip_prefix = {prefix},\n"
            "        sha256 = {sha},\n"
            "        integrity = {integ},\n"
            "        patches = {patches},\n"
            "    ),".format(
                ver=_q(version),
                urls=urls_lines,
                prefix=_q(prefix),
                sha=_q(meta.get("sha256", "")),
                integ=_q(meta.get("integrity", "")),
                patches=_format_patches(meta.get("patches", [])),
            )
        )
    body = "\n".join(entries)
    return "{var} = {{\n{body}\n}}\n".format(var=varname, body=body)


def emit_source_dict(*args, **kwargs):
    """Emit a ``*_versions.bzl`` file body for a single source-mode dict."""
    return GEN_HEADER + render_source_dict(*args, **kwargs)


def render_binary_dict(varname, versions):
    """Render a ``{version: {(os, arch): struct(...)}}`` literal for binary-mode tools.

    Versions are emitted in lexicographic order to keep buildifier happy.
    """
    out = ["{} = {{\n".format(varname)]
    for version in sorted(versions.keys()):
        out.append("    {}: {{\n".format(_q(version)))
        plats = versions[version]
        for os_arch in sorted(plats.keys()):
            entry = plats[os_arch]
            urls_lines = (
                "[\n"
                + "".join("                {},\n".format(_q(u)) for u in entry["urls"])
                + "            ]"
            )
            constraints_lines = (
                "[\n"
                + "".join(
                    "                {},\n".format(_q(c)) for c in entry["constraints"]
                )
                + "            ]"
            )
            key_literal = "({})".format(", ".join(_q(p) for p in os_arch))
            out.append(
                "        {key}: struct(\n"
                "            urls = {urls},\n"
                "            strip_prefix = {prefix},\n"
                "            sha256 = {sha},\n"
                "            integrity = {integ},\n"
                "            constraints = {constraints},\n"
                "            bin = {bin},\n"
                "        ),\n".format(
                    key=key_literal,
                    urls=urls_lines,
                    prefix=_q(entry["strip_prefix"]),
                    sha=_q(entry.get("sha256", "")),
                    integ=_q(entry.get("integrity", "")),
                    constraints=constraints_lines,
                    bin=_q(entry.get("bin", "")),
                )
            )
        out.append("    },\n")
    out.append("}\n")
    return "".join(out)


def render_wildcard_map(varname, versions):
    """Render a ``{"<major>.<minor>.x": "<exact>"}`` literal.

    Lets the binary spoke helpers accept a ``<major>.<minor>.x`` wildcard and
    resolve it to the latest patch, matching the version inputs the previous
    if-cascade in prebuilt_toolchains.bzl accepted.
    """
    out = ["{} = {{\n".format(varname)]
    for version in sorted(versions.keys()):
        major, minor, _patch = version.split(".")
        wildcard = "{}.{}.x".format(major, minor)
        out.append("    {}: {},\n".format(_q(wildcard), _q(version)))
    out.append("}\n")
    return "".join(out)


# ---------------------------------------------------------------------------
# Per-tool data fetch
# ---------------------------------------------------------------------------


def get_cmake_definitions():
    """Build the CMAKE_BIN_SRCS and CMAKE_SRC_SRCS data dicts.

    Returns:
        (bin_versions, src_versions), both keyed by version string.
    """
    bin_versions = {}
    src_versions = {}

    for minor_series in CMAKE_MINORS:
        version = latest_cmake_patch(minor_series)
        major, minor, patch = version.split(".")

        minor_version = "{}.{}".format(major, minor)
        sha_url = CMAKE_SHA256_URL_TEMPLATE.format(minor=minor_version, full=version)

        cached = _SHA_CACHE.get(sha_url)
        if cached is None:
            print("fetching cmake {}".format(version))
            cached = urllib.request.urlopen(sha_url).read().decode("utf-8")
            _SHA_CACHE[sha_url] = cached
        per_plat = {}
        for line in cached.splitlines():
            line = line.strip("\n ")

            # Only take tar and zip files. The rest can't be easily decompressed.
            if not line.endswith(".tar.gz") and not line.endswith(".zip"):
                continue

            # Only include the targets we care about.
            plat_target = None
            for target in CMAKE_TARGETS.keys():
                if target in line:
                    plat_target = target
                    break

            sha256, file = line.split()

            if not plat_target:
                if line.endswith("cmake-{}.{}.{}.tar.gz".format(major, minor, patch)):
                    entry = {
                        "urls": [CMAKE_URL_TEMPLATE.format(full=version, file=file)],
                        # Explicit so the `.x` alias below reuses the exact-patch
                        # directory name; render_source_dict would otherwise
                        # derive "cmake-3.19.x" from the alias key.
                        "strip_prefix": "cmake-{}.{}.{}".format(major, minor, patch),
                        "sha256": sha256,
                        "patches": [],
                    }
                    src_versions["{}.{}.{}".format(major, minor, patch)] = entry
                    # `.x` wildcard alias: same entry under the minor-series key
                    # so a `<major>.<minor>.x` request can resolve to the latest
                    # patch. The resolution from `.x` to the exact patch happens
                    # before a repo is minted, so source_spokes.bzl only ever sees
                    # an exact version and never mints a `@<tool>_src_<minor>.x`.
                    src_versions["{}.{}.x".format(major, minor)] = entry
                continue

            name = file.replace(".tar.gz", "").replace(".zip", "")
            bin_name = "cmake.exe" if "win" in file.lower() else "cmake"

            if "Darwin" in file or "macos" in file:
                prefix = name + "/CMake.app/Contents"
            else:
                prefix = name

            target_meta = CMAKE_TARGETS[plat_target]
            os_arch = target_meta["os_arch"]
            per_plat[os_arch] = {
                "urls": [CMAKE_URL_TEMPLATE.format(full=version, file=file)],
                "strip_prefix": prefix,
                "sha256": sha256,
                "integrity": "",
                "constraints": list(target_meta["constraints"]),
                "bin": bin_name,
            }
        bin_versions[version] = per_plat

    return bin_versions, src_versions


def get_ninja_definitions(latest_by_minor):
    """Build the NINJA_BIN_SRCS data dict from a resolved {minor: patch} map.

    The same resolved patch set feeds the source dict in main(), so the binary
    and source modes always ship the identical ninja versions.

    Returns:
        bin_versions, keyed by version string.
    """
    bin_versions = {}

    for minor_series in NINJA_MINORS:
        version = latest_by_minor[minor_series]
        supports_linux_aarch64 = version not in [
            "1.10.0",
            "1.10.1",
            "1.10.2",
            "1.11.0",
            "1.11.1",
        ]
        supports_mac_universal = version not in ["1.10.0", "1.10.1"]
        per_plat = {}

        for target, target_meta in NINJA_TARGETS.items():
            if not supports_linux_aarch64 and target == "linux-aarch64":
                continue
            if not supports_mac_universal and target == "mac_aarch64":
                continue

            url = NINJA_URL_TEMPLATE.format(
                full=version,
                target="mac" if target == "mac_aarch64" else target,
            )

            sha256 = _SHA_CACHE.get(url)
            if sha256 is None:
                print("fetching {}".format(url))
                sha256 = _sha256_of(url)
                _SHA_CACHE[url] = sha256

            os_arch = target_meta["os_arch"]
            per_plat[os_arch] = {
                "urls": [url],
                "strip_prefix": "",
                "sha256": sha256,
                "integrity": "",
                "constraints": list(target_meta["constraints"]),
                "bin": "ninja.exe" if "win" in target else "ninja",
            }

        bin_versions[version] = per_plat

    return bin_versions


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------


def main():
    """Regenerate every per-tool version dict file under toolchains/private/.

    ``binary_spokes.bzl``, ``source_spokes.bzl`` and ``prebuilt_toolchains.bzl``
    are hand-maintained and NOT written here -- only the ``*_versions.bzl`` data
    modules are generated.
    """
    out_dir = Path(__file__).parent.absolute()
    private_dir = out_dir / "private"
    private_dir.mkdir(exist_ok=True)

    def _write(path, text):
        path.write_text(text)
        print("wrote {}".format(path.relative_to(out_dir.parent)))

    cmake_bin, cmake_src = get_cmake_definitions()

    # Resolve the ninja patch set once; both modes ship the same versions.
    ninja_latest = latest_ninja_patches(NINJA_MINORS)
    ninja_bin = get_ninja_definitions(ninja_latest)
    ninja_src_versions = {
        version: list(NINJA_SRC_PATCHES.get(version, []))
        for version in ninja_latest.values()
    }

    # --- per-tool version dicts under toolchains/private/ ---
    cmake_versions_text = (
        GEN_HEADER
        + render_binary_dict("CMAKE_BIN_SRCS", cmake_bin)
        + "\n"
        + render_wildcard_map("CMAKE_BIN_WILDCARDS", cmake_bin)
        + "\n"
        + render_source_dict(
            varname="CMAKE_SRC_SRCS",
            url_template="",  # cmake source uses an explicit `urls` override per entry
            fallback_template=None,
            versions=cmake_src,
            prefix_template="cmake-{version}",
        )
    )
    _write(private_dir / "cmake_versions.bzl", cmake_versions_text)

    ninja_versions_text = (
        GEN_HEADER
        + render_binary_dict("NINJA_BIN_SRCS", ninja_bin)
        + "\n"
        + render_wildcard_map("NINJA_BIN_WILDCARDS", ninja_bin)
        + "\n"
        + render_source_dict(
            varname="NINJA_SRC_SRCS",
            url_template="",  # explicit `urls` override per entry
            fallback_template=None,
            versions=add_source_wildcards(
                hashed_source_versions(
                    "ninja",
                    ninja_src_versions,
                    NINJA_SRC_URL_TEMPLATE,
                    NINJA_SRC_URL_FALLBACK,
                ),
                "",
                None,
                "ninja-{version}",
            ),
            prefix_template="ninja-{version}",
        )
    )
    _write(private_dir / "ninja_versions.bzl", ninja_versions_text)

    _write(
        private_dir / "make_versions.bzl",
        emit_source_dict(
            varname="GNUMAKE_SRCS",
            url_template="",  # explicit `urls` override per entry
            fallback_template=None,
            versions=add_source_wildcards(
                hashed_source_versions(
                    "make", MAKE_VERSIONS, MAKE_URL_TEMPLATE, MAKE_URL_FALLBACK
                ),
                "",
                None,
                "make-{version}",
            ),
            prefix_template="make-{version}",
        ),
    )

    _write(
        private_dir / "meson_versions.bzl",
        emit_source_dict(
            varname="MESON_SRCS",
            url_template="",  # explicit `urls` override per entry
            fallback_template=None,
            versions=add_source_wildcards(
                hashed_source_versions(
                    "meson", MESON_VERSIONS, MESON_URL_TEMPLATE, MESON_URL_FALLBACK
                ),
                "",
                None,
                "meson-{version}",
            ),
            prefix_template="meson-{version}",
        ),
    )

    _write(
        private_dir / "pkgconfig_versions.bzl",
        emit_source_dict(
            varname="PKGCONFIG_SRCS",
            url_template="",  # explicit `urls` override per entry
            fallback_template=None,
            versions=add_source_wildcards(
                hashed_source_versions(
                    "pkgconfig",
                    PKGCONFIG_VERSIONS,
                    PKGCONFIG_URL_TEMPLATE,
                    PKGCONFIG_URL_FALLBACK,
                ),
                "",
                None,
                "pkg-config-{version}",
            ),
            prefix_template="pkg-config-{version}",
        ),
    )

    _save_sha_cache(_SHA_CACHE)


if __name__ == "__main__":
    main()
