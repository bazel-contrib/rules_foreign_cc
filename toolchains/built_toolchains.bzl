"""Legacy WORKSPACE entry point for source-mode toolchains.

This is a thin shim over the per-tool spoke helpers in
``//toolchains/private:source_spokes.bzl``. It will be deleted when WORKSPACE
support is dropped, expected around 2027-12-31 when Bazel 8 reaches
end-of-life (the CI matrix still runs Bazel 7.x/8.x in WORKSPACE mode until
then), so it is long-lived enough to keep in sync with the bzlmod path.
"""

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:tool_specs.bzl", "BCR_SOURCE_TOOLS", "SPOKE_SOURCE_TOOLS", "get_spec")

# buildifier: disable=bzl-visibility
load("//toolchains/private:hub.bzl", "hub_repo", "source_spoke_aliases")
load(
    "//toolchains/private:source_spokes.bzl",
    "cmake_source_spokes",
    "meson_source_spokes",
    "source_spoke_repo",
)

# buildifier: disable=unnamed-macro
def built_toolchains(
        cmake_version,
        m4_version,
        make_version,
        ninja_version,
        meson_version,
        pkgconfig_version,
        register_toolchains,
        register_built_pkgconfig_toolchain):
    """Register toolchains for built tools that will be built from source.

    Args:
        cmake_version: The CMake version to build
        m4_version: The m4 version, used the same way as `make_version`.
        make_version: The make version. Not built here -- `bcr_repos` in
            `//foreign_cc:repositories.bzl` fetches the registry module at this
            version; it only names the `@make_src_<version>` compat repo.
        ninja_version: The ninja version, used the same way as `make_version`.
        meson_version: The Meson version to build
        pkgconfig_version: The pkgconf version, used the same way as
            `make_version`.
        register_toolchains: If true, registers the toolchains via native.register_toolchains. Used by bzlmod
        register_built_pkgconfig_toolchain: If true, the built pkgconfig toolchain will be registered.
    """
    cmake_source_spokes(cmake_version, register_toolchains = register_toolchains)
    meson_source_spokes(meson_version, register_toolchains = register_toolchains)

    # Every source-mode tool's version. SPOKE_SOURCE_TOOLS and
    # BCR_SOURCE_TOOLS partition the same set, so a new source tool surfaces as
    # a load-time KeyError here rather than as a silent omission below.
    versions_by_tool = {
        "cmake": cmake_version,
        "m4": m4_version,
        "make": make_version,
        "meson": meson_version,
        "ninja": ninja_version,
        "pkgconfig": pkgconfig_version,
    }

    _emit_bcr_spokes(versions_by_tool)

    # These wrap binaries built by registry modules, which
    # //foreign_cc:repositories.bzl declares. The targets carry no version:
    # only one @m4 / @make / @ninja / @pkgconf exists per build. The spokes
    # above publish equivalent but unregistered toolchain() targets.
    #
    # Derived from the spec, so a newly registry-backed tool registers without
    # a literal to update here -- an omission would be silent, the tool simply
    # falling down its ladder to `system`. //toolchains/private:BUILD.bazel
    # names each toolchain() after the native_tool_toolchain it wraps; drifting
    # from that surfaces as a no-such-target error during resolution.
    if register_toolchains:
        for tool in BCR_SOURCE_TOOLS:
            # Gated separately, as it always has been: this one has a
            # dedicated opt-out.
            if tool == "pkgconfig" and not register_built_pkgconfig_toolchain:
                continue
            native.register_toolchains(get_spec(tool).source_target + "_toolchain")

    _emit_workspace_hub(versions_by_tool)

def _emit_bcr_spokes(versions_by_tool):
    """Publish `@<tool>_src_<v>` repo names for every BCR-backed tool.

    Uniform over `BCR_SOURCE_TOOLS`. For the tools that predate the registry
    switch this keeps a name WORKSPACE consumers could already write --
    `@make_src_4.4.1//:make_toolchain`, `:make_tool` or `:make_built`. Those
    repos no longer hold a source tree, so these stand-ins forward to the
    registry-built binary. `all_srcs` is deliberately absent: there is no
    target in `@m4` / `@make` / `@ninja` / `@pkgconf` to forward it to.
    Generated files, not downloads, so an unused shim is free.

    Bzlmod gets none of this -- an extension's repos aren't nameable without a
    `use_repo`, so the hub aliases were always its only surface.

    Args:
        versions_by_tool: `{tool: version}` covering every source-mode tool.
            Only the BCR-backed ones are read. A falsy version skips that tool.
    """
    for tool in BCR_SOURCE_TOOLS:
        version = versions_by_tool[tool]
        if not version:
            continue

        # The spec's own labels, so renaming the toolchain target or type moves
        # both dependency models together.
        spec = get_spec(tool)
        hub_repo(
            name = source_spoke_repo(tool, version),
            alias_specs_json_list = [json.encode(a) for a in [
                # A cc_binary, where the old target was a foreign_cc install
                # tree: `$(execpath)` names the executable, not a directory
                # holding `bin/<tool>`.
                {"actual": spec.bcr_binary, "name": "{}_built".format(tool)},
                {"actual": spec.source_target, "name": "{}_tool".format(tool)},
            ]],
            toolchain_specs_json_list = [json.encode({
                "name": "{}_toolchain".format(tool),
                "toolchain": spec.source_target,
                "toolchain_type": spec.toolchain_type,
            })],
        )

def _emit_workspace_hub(versions_by_tool):
    """Synthesize @rules_foreign_cc_toolchains under WORKSPACE.

    Bzlmod creates this hub via foreign_cc/extensions.bzl. WORKSPACE consumers
    don't run that extension, so macros that reference hub-published aliases
    (e.g. meson_with_requirements) would otherwise hit "no such repository".
    Emit a minimal hub here that publishes the source-spoke aliases the
    bzlmod hub does, so those macros keep working.

    Args:
        versions_by_tool: `{tool: version}` covering every source-mode tool.
    """

    # Spoke tools get the full alias set; the BCR-backed ones get only
    # `<tool>_built`, because their registry BUILD files define nothing else to
    # alias -- no `<tool>_src_all`, see _emit_bcr_spokes.
    aliases = []
    for tool in SPOKE_SOURCE_TOOLS:
        if versions_by_tool[tool]:
            aliases.extend(source_spoke_aliases(tool, versions_by_tool[tool]))

    # Kept for WORKSPACE consumers who already name these; the bzlmod hub
    # dropped them. Pointed straight at the binary rather than through the
    # compat shim above, so the hub doesn't depend on a legacy-label repo.
    for tool in BCR_SOURCE_TOOLS:
        if versions_by_tool[tool]:
            aliases.append({
                "actual": get_spec(tool).bcr_binary,
                "name": "{}_built".format(tool),
            })

    aliases = sorted(aliases, key = lambda d: d["name"])
    hub_repo(
        name = "rules_foreign_cc_toolchains",
        alias_specs_json_list = [json.encode(a) for a in aliases],
        toolchain_specs_json_list = [],
    )
