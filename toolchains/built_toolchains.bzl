"""Legacy WORKSPACE entry point for source-mode toolchains.

This is a thin shim over the per-tool spoke helpers in
``//toolchains/private:source_spokes.bzl``. It will be deleted when WORKSPACE
support is dropped, expected around 2027-12-31 when Bazel 8 reaches
end-of-life (the CI matrix still runs Bazel 7.x/8.x in WORKSPACE mode until
then), so it is long-lived enough to keep in sync with the bzlmod path.
"""

# buildifier: disable=bzl-visibility
load("//toolchains/private:hub.bzl", "hub_repo", "source_spoke_aliases")
load(
    "//toolchains/private:source_spokes.bzl",
    "cmake_source_spokes",
    "make_source_spokes",
    "meson_source_spokes",
    "ninja_source_spokes",
    "pkgconfig_source_spokes",
)

# buildifier: disable=unnamed-macro
def built_toolchains(
        cmake_version,
        make_version,
        ninja_version,
        meson_version,
        pkgconfig_version,
        register_toolchains,
        register_built_pkgconfig_toolchain):
    """Register toolchains for built tools that will be built from source.

    Args:
        cmake_version: The CMake version to build
        make_version: The Make version to build
        ninja_version: The Ninja version to build
        meson_version: The Meson version to build
        pkgconfig_version: The pkg-config version to build
        register_toolchains: If true, registers the toolchains via native.register_toolchains. Used by bzlmod
        register_built_pkgconfig_toolchain: If true, the built pkgconfig toolchain will be registered.
    """
    cmake_source_spokes(cmake_version, register_toolchains = register_toolchains)
    make_source_spokes(make_version, register_toolchains = register_toolchains)
    ninja_source_spokes(ninja_version, register_toolchains = register_toolchains)
    meson_source_spokes(meson_version, register_toolchains = register_toolchains)

    # pkgconfig's spoke is always materialized so the hub can alias it
    # (pkgconfig_built / pkgconfig_src_all) just like the bzlmod path does,
    # regardless of whether its toolchain is registered. Only the registration
    # is gated on register_built_pkgconfig_toolchain -- the flag suppresses the
    # toolchain, not the source archive or its aliases.
    pkgconfig_source_spokes(
        pkgconfig_version,
        register_toolchains = register_toolchains and register_built_pkgconfig_toolchain,
    )

    _emit_workspace_hub(
        cmake_version,
        make_version,
        ninja_version,
        meson_version,
        pkgconfig_version,
    )

def _emit_workspace_hub(cmake_version, make_version, ninja_version, meson_version, pkgconfig_version):
    """Synthesize @rules_foreign_cc_toolchains under WORKSPACE.

    Bzlmod creates this hub via foreign_cc/extensions.bzl. WORKSPACE consumers
    don't run that extension, so macros that reference hub-published aliases
    (e.g. meson_with_requirements) would otherwise hit "no such repository".
    Emit a minimal hub here that publishes the source-spoke aliases the
    bzlmod hub does, so those macros keep working.
    """
    versions_by_tool = [
        ("cmake", cmake_version),
        ("ninja", ninja_version),
        ("make", make_version),
        ("meson", meson_version),
        ("pkgconfig", pkgconfig_version),
    ]
    aliases = []
    for tool, version in versions_by_tool:
        if not version:
            continue
        aliases.extend(source_spoke_aliases(tool, version))
    aliases = sorted(aliases, key = lambda d: d["name"])
    hub_repo(
        name = "rules_foreign_cc_toolchains",
        alias_specs_json_list = [json.encode(a) for a in aliases],
        toolchain_specs_json_list = [],
    )
