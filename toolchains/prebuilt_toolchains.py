#!/usr/bin/env python3
"""Generator for rules_foreign_cc prebuilt (binary) toolchain data.

It emits the binary version dicts ``toolchains/private/{cmake,ninja}_versions.bzl``
plus ``toolchains/private/binary_spokes.bzl`` containing the cmake/ninja binary
spoke helpers.  ``toolchains/prebuilt_toolchains.bzl`` is hand-maintained and is
NOT overwritten by this generator. Source-mode tool data remains hand-maintained
in ``toolchains/built_toolchains.bzl`` for now.

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

# ---------------------------------------------------------------------------
# CMake (binary)
# ---------------------------------------------------------------------------


def _log(msg):
    """Print a progress line to stderr immediately (unbuffered)."""
    print(msg, file=sys.stderr, flush=True)


def _fetch(url):
    return urllib.request.urlopen(url).read().decode("utf-8", "replace")


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


CMAKE_DIR_URL_TEMPLATE = "https://cmake.org/files/v{minor}/"
CMAKE_SHA256_URL_TEMPLATE = "https://cmake.org/files/v{minor}/cmake-{full}-SHA-256.txt"
CMAKE_URL_TEMPLATE = "https://github.com/Kitware/CMake/releases/download/v{full}/{file}"
NINJA_RELEASES_URL = (
    "https://api.github.com/repos/ninja-build/ninja/releases?per_page=100"
)

# Minor series to support. The latest patch within each is auto-discovered.
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

# ---------------------------------------------------------------------------
# Ninja (binary)
# ---------------------------------------------------------------------------

NINJA_URL_TEMPLATE = (
    "https://github.com/ninja-build/ninja/releases/download/v{full}/ninja-{target}.zip"
)

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

# Minor series to support. The latest patch within each is auto-discovered.
NINJA_MINORS = (
    "1.13",
    "1.12",
    "1.11",
    "1.10",
    "1.9",
    "1.8",
)

# ---------------------------------------------------------------------------
# Visibility header emitted on every generated ``*_versions.bzl``.
# ---------------------------------------------------------------------------

GEN_HEADER = (
    '"""@generated by toolchains/prebuilt_toolchains.py — do not edit."""\n\n'
    "visibility([\n"
    '    "//foreign_cc",\n'
    '    "//foreign_cc/private",\n'
    '    "//toolchains",\n'
    "])\n\n"
)


def _q(s):
    """Render a Starlark string literal with double quotes (buildifier style)."""
    return json.dumps(s, ensure_ascii=False)


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
                "            plat_target = {plat_target},\n"
                "        ),\n".format(
                    key=key_literal,
                    urls=urls_lines,
                    prefix=_q(entry["strip_prefix"]),
                    sha=_q(entry.get("sha256", "")),
                    integ=_q(entry.get("integrity", "")),
                    constraints=constraints_lines,
                    bin=_q(entry.get("bin", "")),
                    plat_target=_q(entry.get("plat_target", "")),
                )
            )
        out.append("    },\n")
    out.append("}\n")
    return "".join(out)


def render_wildcard_map(varname, versions):
    """Render a ``{"<major>.<minor>.x": "<exact>"}`` literal.

    Lets the spoke helpers accept a ``<major>.<minor>.x`` wildcard and resolve
    it to the latest patch, matching the version inputs the previous
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
# Binary-mode data fetch
# ---------------------------------------------------------------------------


def get_cmake_definitions():
    """Build the CMAKE_BIN_SRCS data dict.

    Returns:
        bin_versions — keyed by version string.
    """
    bin_versions = {}

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

            # Non-platform rows (e.g. the source tarball) are not part of the
            # binary data this generator emits.
            if not plat_target:
                continue

            sha256, file = line.split()

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
                # The upstream "plat_target" string. Used by binary_spokes.bzl
                # to derive the per-platform repo name (kept byte-identical
                # with the previous if-cascade).
                "plat_target": plat_target,
            }
        bin_versions[version] = per_plat

    return bin_versions


def get_ninja_definitions():
    """Build the NINJA_BIN_SRCS data dict.

    Returns:
        bin_versions — keyed by version string.
    """
    bin_versions = {}

    latest_by_minor = latest_ninja_patches(NINJA_MINORS)
    for minor_series in NINJA_MINORS:
        version = latest_by_minor[minor_series]
        supports_linux_aarch64 = version not in [
            "1.8.2",
            "1.9.0",
            "1.10.0",
            "1.10.1",
            "1.10.2",
            "1.11.0",
            "1.11.1",
        ]
        supports_mac_universal = version not in ["1.8.2", "1.9.0", "1.10.0", "1.10.1"]
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
                # Get sha256 (can be slow)
                remote = urllib.request.urlopen(url)
                total_read = 0
                max_file_size = 100 * 1024 * 1024
                h = hashlib.sha256()
                while True:
                    data = remote.read(4096)
                    total_read += 4096
                    if not data or total_read > max_file_size:
                        break
                    h.update(data)
                sha256 = h.hexdigest()
                _SHA_CACHE[url] = sha256

            os_arch = target_meta["os_arch"]
            per_plat[os_arch] = {
                "urls": [url],
                "strip_prefix": "",
                "sha256": sha256,
                "integrity": "",
                "constraints": list(target_meta["constraints"]),
                "bin": "ninja.exe" if "win" in target else "ninja",
                "plat_target": target,
            }

        bin_versions[version] = per_plat

    return bin_versions


# ---------------------------------------------------------------------------
# binary_spokes.bzl emission (loop-driven, dict-fed)
# ---------------------------------------------------------------------------

BINARY_SPOKES_BZL_TEMPLATE = '''"""@generated by toolchains/prebuilt_toolchains.py — do not edit."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@rules_foreign_cc//toolchains/private:cmake_versions.bzl", "CMAKE_BIN_SRCS", "CMAKE_BIN_WILDCARDS")
load("@rules_foreign_cc//toolchains/private:ninja_versions.bzl", "NINJA_BIN_SRCS", "NINJA_BIN_WILDCARDS")
load("@rules_foreign_cc//toolchains/private:prebuilt_toolchains_repository.bzl", "prebuilt_toolchains_repository")

visibility([
    "//foreign_cc",
    "//foreign_cc/private",
    "//toolchains",
])

_CMAKE_BUILD_FILE = """\\
load("@rules_foreign_cc//toolchains/native_tools:native_tools_toolchain.bzl", "native_tool_toolchain")

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "cmake_bin",
    srcs = ["bin/{{bin}}"],
)

filegroup(
    name = "cmake_data",
    srcs = glob(
        [
            "**",
        ],
        exclude = [
            "WORKSPACE",
            "WORKSPACE.bazel",
            "BUILD",
            "BUILD.bazel",
            "**/* *",
        ],
    ),
)

native_tool_toolchain(
    name = "cmake_tool",
    path = "bin/{{bin}}",
    target = ":cmake_data",
    env = {{env}},
    tools = [":cmake_bin"],
)
"""

_NINJA_BUILD_FILE = """\\
load("@rules_foreign_cc//toolchains/native_tools:native_tools_toolchain.bzl", "native_tool_toolchain")
load("@rules_foreign_cc//foreign_cc/private:select_executable.bzl", "select_executable")

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "ninja_bin",
    srcs = ["{{bin}}"],
)

select_executable(
    name = "ninja_wrapper_bin",
    src = "{{wrapper}}",
)

filegroup(
    name = "ninja_data",
    srcs = [
        ":ninja_bin",
        "{{wrapper}}",
    ]
)

native_tool_toolchain(
    name = "ninja_tool",
    env = {{env}},
    path = "$(execpath :ninja_wrapper_bin)",
    target = ":ninja_data",
    tools = [
        ":ninja_bin",
        ":ninja_wrapper_bin",
    ]
)
"""

def _http_archive_kwargs(spec):
    kwargs = dict(
        urls = spec.urls,
        strip_prefix = spec.strip_prefix,
    )
    if spec.sha256:
        kwargs["sha256"] = spec.sha256
    if spec.integrity:
        kwargs["integrity"] = spec.integrity
    return kwargs

def _resolve_version(version, wildcards):
    """Map a `<major>.<minor>.x` wildcard to its latest patch; pass others through."""
    return wildcards.get(version, version)

# buildifier: disable=unnamed-macro
def cmake_binary_spokes(version, register_toolchains = False):
    """Define per-platform prebuilt cmake repos and optional toolchain registration.

    Args:
        version: The cmake version to use. Accepts an exact patch (e.g. "3.31.12")
            or a "<major>.<minor>.x" wildcard that resolves to the latest patch.
        register_toolchains: If true, register via native.register_toolchains.
    """
    version = _resolve_version(version, CMAKE_BIN_WILDCARDS)
    plats = CMAKE_BIN_SRCS.get(version)
    if not plats:
        fail("Unsupported version: " + str(version))

    repo_names = []
    repos = {{}}
    for _os_arch, spec in plats.items():
        plat_target = spec.plat_target
        name = "cmake-{{}}-{{}}".format(version, plat_target)
        kwargs = _http_archive_kwargs(spec)
        maybe(
            http_archive,
            name = name,
            build_file_content = _CMAKE_BUILD_FILE.format(
                bin = spec.bin,
                env = {{"CMAKE": "$(execpath :cmake_bin)"}},
            ),
            **kwargs
        )
        repo_names.append(name)
        repos[name] = list(spec.constraints)

    repo_names = sorted(repo_names)

    # buildifier: leave-alone
    maybe(
        prebuilt_toolchains_repository,
        name = "cmake_{{}}_toolchains".format(version),
        repos = repos,
        tool = "cmake",
    )

    if register_toolchains:
        native.register_toolchains(*[
            "@cmake_{{}}_toolchains//:{{}}_toolchain".format(version, name)
            for name in repo_names
        ])

# buildifier: disable=unnamed-macro
def ninja_binary_spokes(version, register_toolchains = False):
    """Define per-platform prebuilt ninja repos and optional toolchain registration.

    Args:
        version: The ninja version to use. Accepts an exact patch (e.g. "1.13.2")
            or a "<major>.<minor>.x" wildcard that resolves to the latest patch.
        register_toolchains: If true, register via native.register_toolchains.
    """
    version = _resolve_version(version, NINJA_BIN_WILDCARDS)
    plats = NINJA_BIN_SRCS.get(version)
    if not plats:
        fail("Unsupported version: " + str(version))

    repo_names = []
    repos = {{}}
    for _os_arch, spec in plats.items():
        plat_target = spec.plat_target
        name = "ninja_{{}}_{{}}".format(version, plat_target)
        kwargs = _http_archive_kwargs(spec)
        maybe(
            http_archive,
            name = name,
            build_file_content = _NINJA_BUILD_FILE.format(
                bin = spec.bin,
                wrapper = "@rules_foreign_cc//toolchains/private:ninja_wrapper",
                env = {{
                    "NINJA": "$(execpath :ninja_wrapper_bin)",
                    "REAL_NINJA": "$(execpath :ninja_bin)",
                }},
            ),
            **kwargs
        )
        repo_names.append(name)
        repos[name] = list(spec.constraints)

    repo_names = sorted(repo_names)

    # buildifier: leave-alone
    maybe(
        prebuilt_toolchains_repository,
        name = "ninja_{{}}_toolchains".format(version),
        repos = repos,
        tool = "ninja",
    )

    if register_toolchains:
        native.register_toolchains(*[
            "@ninja_{{}}_toolchains//:{{}}_toolchain".format(version, name)
            for name in repo_names
        ])
'''


def _strip_internal(versions):
    """Drop generator-internal underscore-prefixed keys before emission.

    All public per-platform fields (including ``plat_target``) flow through
    unchanged.
    """
    cleaned = {}
    for version, plats in versions.items():
        cleaned[version] = {}
        for os_arch, entry in plats.items():
            cleaned[version][os_arch] = {
                k: v for k, v in entry.items() if not k.startswith("_")
            }
    return cleaned


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------


def main():
    """Regenerate every per-tool version dict file plus prebuilt_toolchains.bzl."""
    out_dir = Path(__file__).parent.absolute()
    private_dir = out_dir / "private"
    private_dir.mkdir(exist_ok=True)

    def _write(path, text):
        path.write_text(text)
        print("wrote {}".format(path.relative_to(out_dir.parent)))

    cmake_bin = get_cmake_definitions()
    ninja_bin = get_ninja_definitions()

    # --- per-tool binary version dicts under toolchains/private/ ---
    # This generator currently emits only the binary (prebuilt) data. The
    # source-mode dicts and the source-build entry point in built_toolchains.bzl
    # remain hand-maintained; they move under the generator in a later change.
    cmake_bin = _strip_internal(cmake_bin)
    ninja_bin = _strip_internal(ninja_bin)
    _write(
        private_dir / "cmake_versions.bzl",
        GEN_HEADER
        + render_binary_dict("CMAKE_BIN_SRCS", cmake_bin)
        + "\n"
        + render_wildcard_map("CMAKE_BIN_WILDCARDS", cmake_bin),
    )

    _write(
        private_dir / "ninja_versions.bzl",
        GEN_HEADER
        + render_binary_dict("NINJA_BIN_SRCS", ninja_bin)
        + "\n"
        + render_wildcard_map("NINJA_BIN_WILDCARDS", ninja_bin),
    )

    # --- toolchains/private/binary_spokes.bzl (auto-generated, loops over the dicts) ---
    # Note: toolchains/prebuilt_toolchains.bzl is hand-maintained and NOT written here.
    # The template uses doubled `{{`/`}}` for literal Starlark braces; calling
    # .format() with no kwargs unescapes them to single braces.
    _write(private_dir / "binary_spokes.bzl", BINARY_SPOKES_BZL_TEMPLATE.format())

    _save_sha_cache(_SHA_CACHE)


if __name__ == "__main__":
    main()
