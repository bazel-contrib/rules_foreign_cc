"""Module extension `tools` for rules_foreign_cc.

Emits one hub repo (@rules_foreign_cc_toolchains) and per-tool spoke repos.
"""

load("@bazel_features//:features.bzl", "bazel_features")
load("//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")
load(
    "//foreign_cc/private:extension_impl.bzl",
    "all_required_spokes",
    "build_hub_aliases",
    "build_hub_plan",
    "collect_tags",
    "validate_tag",
)
load(
    "//foreign_cc/private:tool_specs.bzl",
    "ALL_MODES",
    "ALL_TOOLS",
    "MODE_BINARY",
    "MODE_NOOP",
    "MODE_SOURCE",
    "MODE_SYSTEM",
)
load("//toolchains:toolchains.bzl", "PREINSTALLED_TOOLS")

# buildifier: disable=bzl-visibility
load("//toolchains/private:binary_spokes.bzl", "cmake_binary_spokes", "ninja_binary_spokes")

# buildifier: disable=bzl-visibility
load("//toolchains/private:hub.bzl", "hub_repo")

# buildifier: disable=bzl-visibility
load(
    "//toolchains/private:source_spokes.bzl",
    "cmake_source_spokes",
    "make_source_spokes",
    "meson_source_spokes",
    "ninja_source_spokes",
    "pkgconfig_source_spokes",
)

# Shared attribute set for every tool's tag class: the attributes needed
# for default mode, register_toolchain opt-out, and noop. Adding attributes
# is not a breaking change, so the set can grow as new functionality lands.
_COMMON_TAG_ATTRS = {
    "exec_compatible_with": attr.label_list(default = []),
    # "" means "unset" (accept the tool's default mode); the rest mirror
    # ALL_MODES so the accepted set can't drift from the planner's modes.
    "mode": attr.string(default = "", values = [""] + ALL_MODES),
    "register_toolchain": attr.bool(default = True),
    "target_compatible_with": attr.label_list(default = []),
    "version": attr.string(default = ""),
}

# One tag class per tool. The schema is identical; the class name only
# disambiguates which tool the tag refers to. Building this from ALL_TOOLS
# (rather than a hand-written mirror) guarantees every tool is taggable --
# a tool added to TOOL_SPECS but missing here would otherwise be silently
# un-taggable (getattr(mod.tags, tool, []) returns []).
_TAG_CLASSES = {tool: tag_class(attrs = _COMMON_TAG_ATTRS) for tool in ALL_TOOLS}

# Marker tag class with no attributes.
explicit = tag_class(attrs = {})

# Maps (tool, mode) to the repository-rule macro that materializes its spoke.
# The spoke macros take a single version arg, so they're referenced directly --
# no per-tool wrapper needed.
_SPOKE_DISPATCH = {
    "cmake": {
        MODE_BINARY: cmake_binary_spokes,
        MODE_SOURCE: cmake_source_spokes,
    },
    "make": {MODE_SOURCE: make_source_spokes},
    "meson": {MODE_SOURCE: meson_source_spokes},
    "ninja": {
        MODE_BINARY: ninja_binary_spokes,
        MODE_SOURCE: ninja_source_spokes,
    },
    "pkgconfig": {MODE_SOURCE: pkgconfig_source_spokes},
}

def _materialize_spoke(spoke):
    """Call the right repository_rule for a spoke descriptor.

    For mode=system and mode=noop, no spoke is needed (the hub references
    static @rules_foreign_cc//toolchains targets).
    """
    tool, mode, version = spoke["tool"], spoke["mode"], spoke["version"]
    if mode in (MODE_SYSTEM, MODE_NOOP):
        return

    dispatch = _SPOKE_DISPATCH.get(tool, {})
    fn = dispatch.get(mode)
    if not fn:
        fail("internal error: no spoke dispatch for tool={} mode={}".format(tool, mode))
    fn(version)

def _assert_defaults_match_workspace(default_tags):
    """Fail if rfcc's bzlmod default registrations diverge from the WORKSPACE.

    rfcc declares its default toolchain registrations twice: as default tags in
    its own MODULE.bazel (the bzlmod path, bucketed into `default_tags`) and as
    the `PREINSTALLED_TOOLS` list driving `preinstalled_toolchains()` (the
    WORKSPACE path). The two must name the same set of tools, or a `bazel build`
    under one path registers a tool the other doesn't (e.g. nmake creeping into
    the bzlmod defaults would shadow make on Windows).

    This runs only when rfcc is itself the root module (see `_init`), so it
    costs nothing for downstream consumers: it's a guard against an rfcc
    maintainer editing one path and forgetting the other, caught at load time
    rather than by a divergent build.
    """
    bzlmod_tools = sorted([
        tool
        for tool, tags in default_tags.items()
        if [t for t in tags if t["register_toolchain"]]
    ])
    workspace_tools = sorted(PREINSTALLED_TOOLS)
    if bzlmod_tools != workspace_tools:
        only_bzlmod = sorted([t for t in bzlmod_tools if t not in workspace_tools])
        only_workspace = sorted([t for t in workspace_tools if t not in bzlmod_tools])
        fail(("rules_foreign_cc default registrations are out of sync between " +
              "the bzlmod path (default tags in MODULE.bazel) and the WORKSPACE " +
              "path (PREINSTALLED_TOOLS in toolchains/toolchains.bzl): " +
              "bzlmod-only={} workspace-only={}. Update both so they register " +
              "the same set of tools.").format(only_bzlmod, only_workspace))

def _init(module_ctx):
    # Bring in the always-on framework + legacy dependency wiring. We pass
    # register_*=False because the hub now owns registrations.
    rules_foreign_cc_dependencies(
        register_toolchains = False,
        register_built_tools = False,
        register_default_tools = False,
        register_preinstalled_tools = False,
        register_built_pkgconfig_toolchain = False,
        register_repos = False,
    )

    tagset = collect_tags(module_ctx.modules)

    # Validate every tag.
    for tool in ALL_TOOLS:
        for tag in tagset.root_tags[tool]:
            validate_tag(tag)
        for tag in tagset.default_tags[tool]:
            validate_tag(tag)
        for tag in tagset.nonroot_tags[tool]:
            validate_tag(tag)

    # When rfcc is the root module (in-repo dev/test builds), cross-check that
    # its bzlmod default registrations match the WORKSPACE path's. Gated on
    # root so it never runs for downstream consumers.
    if any([m.is_root and m.name == "rules_foreign_cc" for m in module_ctx.modules]):
        _assert_defaults_match_workspace(tagset.default_tags)

    # Materialize spokes (deduplicated by name later via maybe()).
    seen_spokes = {}
    for spoke in all_required_spokes(tagset):
        key = (spoke["tool"], spoke["version"], spoke["mode"])
        if key in seen_spokes:
            continue
        seen_spokes[key] = True
        _materialize_spoke(spoke)

    # Build the hub.
    plan = build_hub_plan(tagset)
    aliases = build_hub_aliases(tagset)
    hub_repo(
        name = "rules_foreign_cc_toolchains",
        alias_specs_json_list = [json.encode(a) for a in aliases],
        toolchain_specs_json_list = [json.encode(e) for e in plan],
    )

    if bazel_features.external_deps.extension_metadata_has_reproducible:
        return module_ctx.extension_metadata(reproducible = True)
    return None

tools = module_extension(
    doc = """Emits the @rules_foreign_cc_toolchains hub plus per-tool spoke repos.

rfcc calls register_toolchains("@rules_foreign_cc_toolchains//:all") from its
own MODULE.bazel, so everything in that target is a registered toolchain.

Precedence:
  1. A spoke is declared for every tools.<tool>(...) tag any module asks for
     (root or transitive, any register_toolchain value). Declaring is lazy;
     Bazel fetches a spoke only when something references its targets.
  2. @rules_foreign_cc_toolchains//:all contains the toolchains the root
     module registers (register_toolchain = True) plus the ones rfcc registers
     by default, root entries first so a root tag wins on conflict. Non-root
     and register_toolchain = False tags never add to it.
  3. tools.explicit() (root-only) drops rfcc's default registrations, leaving
     only the root's own in @rules_foreign_cc_toolchains//:all. Spoke
     declaration is unaffected.
""",
    implementation = _init,
    tag_classes = _TAG_CLASSES | {"explicit": explicit},
)
