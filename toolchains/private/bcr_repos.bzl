"""WORKSPACE reconstruction of the Bazel Central Registry modules rfcc needs.

No-op under bzlmod, where `//MODULE.bazel`'s `bazel_dep`s produce these repos
and the registry client fetches them. WORKSPACE has no registry client, so this
file rebuilds the same repos by hand from the data in
``//toolchains/private:bcr_modules.bzl``.

It needs no bespoke repository rule: `http_archive` already speaks the
registry's vocabulary, because `http_archive` *is* what the registry client
drives.

    source.json          http_archive
    -----------          ------------
    url + mirror_urls -> urls
    integrity         -> integrity
    strip_prefix      -> strip_prefix
    overlay           -> remote_file_urls + remote_file_integrity
    patches           -> remote_patches
    patch_strip       -> remote_patch_strip

So each `BCR_TOOLS` / `BCR_CLOSURE` entry is a transcription of a module's
`source.json`, re-syncing after a bump is a copy of that file plus the new
version string, and the repos come out byte-identical to the bzlmod ones.

Three things bzlmod does that this cannot:

  * MVS. `bcr_repos` just fetches whichever `m4`, `make`, `meson`, `ninja` and
    `pkgconf` the caller of `rules_foreign_cc_dependencies` asked for; a bzlmod
    root reaches the same versions by raising rfcc's `bazel_dep`.
  * Resolve transitive `bazel_dep`s -- hence `BCR_CLOSURE`, holding the modules
    the tool BUILD files need but rfcc never loads from.
  * Guarantee apparent repo names. A BCR BUILD file spells its deps
    `@rules_cc`, `@bazel_skylib`, `@rules_cc_autoconf`; under bzlmod those are
    repo-mapped, under WORKSPACE they are global names. rfcc declares them
    under exactly those names so the same BUILD file resolves either way.

There is deliberately no hook for an rfcc-local patch on top of a module: a
module that needs a fix gets it fixed in the registry and bumped here, so every
consumer shares the fix and both dependency models stay byte-identical.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//toolchains/private:bcr_modules.bzl", "BCR_CLOSURE", "bcr_tool_module")

visibility(["//foreign_cc"])

# The registry commit overlay files and patches are read from. Pinned rather
# than tracking `main`: everything fetched is integrity-checked, so an unpinned
# URL could not silently alter a build, but it could 404 the day the registry
# reorganizes a path. Advance it alongside the versions in `bcr_modules.bzl`,
# to a commit carrying all of them.
_BCR_COMMIT = "40e6f858d7226e67ff66de9609d19d133966508d"

_BCR_RAW = "https://raw.githubusercontent.com/bazelbuild/bazel-central-registry/{}/modules".format(_BCR_COMMIT)

def _registry_url(module, version, kind, path):
    return "/".join([_BCR_RAW, module, version, kind, path])

def _bcr_repo(name, spec):
    """Declare one BCR module as a WORKSPACE repo, mirroring the registry fetch.

    Uses `maybe`, so a consumer that declares the repo itself (a newer make,
    say) wins and rfcc adds nothing.

    Args:
        name: the repo name, which is also the module's name in the registry.
            Used verbatim so the BUILD files fetched from the registry resolve
            their `@`-prefixed deps identically to bzlmod's repo mapping.
        spec: the module struct from `bcr_modules.bzl`.
    """
    version = spec.registry_version

    kwargs = {}
    if spec.overlay:
        kwargs["remote_file_urls"] = {
            path: [_registry_url(name, version, "overlay", path)]
            for path in spec.overlay
        }
        kwargs["remote_file_integrity"] = spec.overlay
    if spec.patches:
        kwargs["remote_patches"] = {
            _registry_url(name, version, "patches", patch): integrity
            for patch, integrity in spec.patches.items()
        }
        kwargs["remote_patch_strip"] = spec.patch_strip

    maybe(
        http_archive,
        name = name,
        integrity = spec.integrity,
        strip_prefix = spec.strip_prefix,
        urls = spec.urls,
        **kwargs
    )

def bcr_repos(m4_version, make_version, meson_version, ninja_version, pkgconfig_version):
    """Declare every BCR module rfcc needs under WORKSPACE.

    Includes the transitive closure that bzlmod would resolve from
    `bazel_dep`, since WORKSPACE has no MVS to do it.

    Args:
        m4_version: the m4 version to fetch; a key of `BCR_TOOLS["m4"]`.
        make_version: the make version to fetch; a key of `BCR_TOOLS["make"]`.
        meson_version: the meson version to fetch; a key of
            `BCR_TOOLS["meson"]`.
        ninja_version: the ninja version to fetch; a key of
            `BCR_TOOLS["ninja"]`. Selects the source-built ninja only. The
            prebuilt one is a separate archive keyed off the same argument, so
            a version offered by only one of the two is rejected by whichever
            mode actually needs it.
        pkgconfig_version: the pkgconf version to fetch; a key of
            `BCR_TOOLS["pkgconf"]`.
    """
    for module, version in [
        ("m4", m4_version),
        ("make", make_version),
        ("meson", meson_version),
        ("ninja", ninja_version),
        ("pkgconf", pkgconfig_version),
    ]:
        _bcr_repo(module, bcr_tool_module(module, version))
    for name in sorted(BCR_CLOSURE):
        _bcr_repo(name, BCR_CLOSURE[name])
