"""Pure functions that turn `module_ctx.modules` into a hub spec.

Side effects (calling repository rules, fetching spokes) live in extensions.bzl.
"""

load(
    "//foreign_cc/private:tool_specs.bzl",
    "ALL_TOOLS",
    "MODE_BINARY",
    "MODE_CUSTOM",
    "MODE_NOOP",
    "MODE_SOURCE",
    "MODE_SYSTEM",
    "SOURCE_TOOLS",
    "exact_versions",
    "get_spec",
    "versions_for_mode",
)
load("//foreign_cc/private/framework/toolchains:mappings.bzl", "TOOLCHAIN_MAPPINGS")

# buildifier: disable=bzl-visibility
load("//toolchains/private:binary_spokes.bzl", "binary_spoke_repo")

# buildifier: disable=bzl-visibility
load("//toolchains/private:custom_spokes.bzl", "custom_spoke_repo")

# buildifier: disable=bzl-visibility
load("//toolchains/private:hub.bzl", "source_spoke_aliases")

# buildifier: disable=bzl-visibility
load("//toolchains/private:source_spokes.bzl", "source_spoke_repo")

def _pad3(n):
    """Zero-pad an int to 3 digits as a string.

    Starlark's str.format does not support format specs like ``{:03d}``,
    so we synthesize the padding by hand. The hub's ``:all`` resolves
    toolchains in lexicographic name order, which equals declaration order
    only while every index is exactly 3 digits -- a 4-digit index would sort
    before a 3-digit one and silently invert precedence. >999 entries of one
    kind for a single tool is implausible, but fail loudly rather than
    reorder the toolchain priority if it ever happens.
    """
    if n > 999:
        fail("_pad3: index {} exceeds 3 digits; the hub's lexicographic :all ordering would invert. Widen the padding.".format(n))
    s = str(n)
    return ("0" * (3 - len(s))) + s if len(s) < 3 else s

# ============================================================
# Tag collection
# ============================================================

def resolve_version(tool, version):
    """Map a `major.minor.x` wildcard to its exact patch; pass others through.

    A known wildcard key (from the tool's `wildcards` map) resolves to its
    latest patch. An exact version, the empty string, or an unknown wildcard
    is returned unchanged so `validate_tag` can reject it with a clear
    message. Resolving here (before the planner runs) means spoke names, hub
    targets, and source aliases all see the exact patch -- so
    `tools.cmake(version="3.31.x")` materializes `@cmake_src_3.31.12`, never
    a literal `@cmake_src_3.31.x`.

    Args:
        tool: tool name string (key into ALL_TOOLS).
        version: a version string: exact patch, `major.minor.x` wildcard, or
            empty.

    Returns:
        The exact patch for a known wildcard; otherwise `version` unchanged.
    """
    if not version:
        return version
    spec = get_spec(tool)
    return spec.wildcards.get(version, version)

def _tag_to_dict(tool, tag):
    """Project a Bazel tag value into a plain dict for testability.

    Makes the rest of the planner testable without a real module_ctx. The
    dict carries exactly the attrs in `_COMMON_TAG_ATTRS`.

    `version` is wildcard-resolved here so every downstream consumer sees an
    exact patch (or the empty string / an unknown value for validate_tag to
    reject).

    The label-valued attrs are stringified. A label in a tag class resolves
    against the *declaring* module's repo mapping, and `str()` on the result
    is the canonical (apparent-name-free) form -- json-safe (the planner's
    output is `json.encode`d into a repository rule) and unambiguous from the
    generated BUILD file it lands in.

    Args:
        tool: tool name string (key into ALL_TOOLS).
        tag: a Bazel tag value object (or any object with the same attrs).

    Returns:
        A plain dict with all tag fields.
    """
    target = getattr(tag, "target", None)
    return {
        "exec_compatible_with": [str(lbl) for lbl in getattr(tag, "exec_compatible_with", [])],
        "mode": getattr(tag, "mode", ""),
        "register_toolchain": getattr(tag, "register_toolchain", True),
        "target": str(target) if target else "",
        "target_compatible_with": [str(lbl) for lbl in getattr(tag, "target_compatible_with", [])],
        "tool": tool,
        "version": resolve_version(tool, getattr(tag, "version", "")),
    }

def collect_tags(modules):
    """Walk modules and return a structured tag set.

    Tags are bucketed by origin into three groups:

      - ``default_tags``: tags from the ``rules_foreign_cc`` module itself.
        These are rfcc's own default registrations (declared in rfcc's
        MODULE.bazel), the lowest priority. A registerable root tag for
        the same tool, or ``tools.explicit()``, suppresses them.
      - ``root_tags``: tags from the root module (the consumer's MODULE.bazel),
        excluding rfcc-when-it-is-root (those are defaults). Highest priority.
      - ``nonroot_tags``: tags from any other transitive module. These only
        fetch spokes for their own scope; they never register or alias.

    When rfcc is itself the root module (in-repo dev/test builds), its tags
    are still defaults -- ``root_tags`` is empty and there is no consumer to
    override them. So the bucket key is the module name, not ``is_root``.

    Args:
        modules: iterable of objects with .name, .is_root and .tags.<tool>.

    Returns:
        struct(
            root_tags = {tool: [tag_dict, ...]},
            nonroot_tags = {tool: [tag_dict, ...]},
            default_tags = {tool: [tag_dict, ...]},  # rfcc's own defaults
            explicit = bool,  # True if any root module has tools.explicit()
        )
    """
    root_tags = {tool: [] for tool in ALL_TOOLS}
    nonroot_tags = {tool: [] for tool in ALL_TOOLS}
    default_tags = {tool: [] for tool in ALL_TOOLS}
    explicit = False
    for mod in modules:
        if mod.name == "rules_foreign_cc":
            bucket = default_tags
        elif mod.is_root:
            bucket = root_tags
        else:
            bucket = nonroot_tags
        for tool in ALL_TOOLS:
            for tag in getattr(mod.tags, tool, []):
                bucket[tool].append(_tag_to_dict(tool, tag))
        if mod.is_root and getattr(mod.tags, "explicit", []):
            # Any non-empty `explicit` tag list from the root sets explicit mode.
            explicit = True
    return struct(
        root_tags = root_tags,
        nonroot_tags = nonroot_tags,
        default_tags = default_tags,
        explicit = explicit,
    )

# ============================================================
# Validation
# ============================================================

def tag_error(tag):
    """Return a descriptive error string if `tag` is invalid, else None.

    Pure (no `fail()`), so the rejection branches are unit-testable in-process
    -- `validate_tag` wraps this with the actual `fail()`.

    A tag is all-or-nothing: writing one at all commits you to specifying it
    completely, and every attr defaults to empty. Declaring no tag for a tool
    inherits rfcc's own registration instead. The rules:

      | attr      | required when          | rejected when          |
      | --------- | ---------------------- | ---------------------- |
      | `mode`    | always                 | not in the tool's list |
      | `version` | mode is binary, source | mode is system, noop,  |
      |           |                        | custom                 |
      | `target`  | mode is custom         | mode is not custom     |

    A version, when present, must also resolve to the tool's known-version
    table *and* to the requested mode's own table. A `major.minor.x` wildcard
    is resolved to its latest patch in `_tag_to_dict` before this runs, so by
    here `version` is always an exact patch (or an unknown value to reject).

    Args:
        tag: tag dict as produced by _tag_to_dict.

    Returns:
        An error message string, or None if the tag is valid.
    """
    spec = get_spec(tag["tool"])
    mode = tag["mode"]
    if not mode:
        # Checked first, so a bare or partially-filled tag reports the missing
        # mode rather than a downstream symptom. Without a mode there is
        # nothing to infer from: `version` alone doesn't identify binary vs
        # source (ninja's tables overlap), and constraints alone identify
        # nothing at all.
        return ("tools.{tool}(): mode is required. Valid modes for {tool}: {modes}. " +
                "To inherit the registration rules_foreign_cc makes itself, drop " +
                "the tag entirely.").format(tool = tag["tool"], modes = spec.modes)
    if tag["tool"] == "nmake" and mode == MODE_NOOP:
        # nmake shares the make_toolchain type and is Windows-only, selected by
        # explicit toolchain= label. A noop nmake entry would carry no platform
        # constraints and so shadow the real make toolchain everywhere. Point
        # users at make's own noop, which noops the same type correctly.
        return ("tools.nmake: mode=\"noop\" is not supported. nmake shares the make " +
                "toolchain type, so use tools.make(mode = \"noop\") to no-op the " +
                "make-family toolchain.")
    if mode not in spec.modes:
        return "tools.{}: mode=\"{}\" is not supported. Valid modes for {}: {}".format(
            tag["tool"],
            mode,
            tag["tool"],
            spec.modes,
        )

    # `custom` wraps a target the consumer already builds, so rfcc has nothing
    # to pick a version of -- and without a target there is nothing to wrap.
    if mode == MODE_CUSTOM and not tag["target"]:
        return "tools.{}: target is required for mode=\"custom\".".format(tag["tool"])
    if mode != MODE_CUSTOM and tag["target"]:
        return "tools.{}: target=\"{}\" is only allowed with mode=\"custom\".".format(
            tag["tool"],
            tag["target"],
        )

    # Versionless tools -- see `VERSIONLESS_TOOLS` -- have no versioned mode, so
    # say that plainly rather than letting the mode-specific message below
    # imply some other mode would have accepted it.
    if spec.known_versions == None and tag["version"]:
        return "tools.{}: version=\"{}\" is not allowed; {} has no versioned mode.".format(
            tag["tool"],
            tag["version"],
            tag["tool"],
        )
    if mode in (MODE_SYSTEM, MODE_NOOP, MODE_CUSTOM) and tag["version"]:
        return "tools.{}: version=\"{}\" is not allowed with mode=\"{}\".".format(
            tag["tool"],
            tag["version"],
            mode,
        )
    if mode in (MODE_BINARY, MODE_SOURCE) and not tag["version"]:
        return "tools.{}: version is required for mode=\"{}\".".format(tag["tool"], mode)

    if tag["version"]:
        known = spec.known_versions
        if known != None and tag["version"] not in known:
            return "tools.{}: version=\"{}\" is not supported. Exact versions: {}. Wildcards: {}.".format(
                tag["tool"],
                tag["version"],
                sorted(known),
                sorted(spec.wildcards.keys()),
            )

        # `known_versions` is the union across modes, so it accepts a version
        # the requested mode can't actually supply. Narrow to that mode's own
        # table: ninja's prebuilt and source versions overlap without
        # coinciding, so mode="binary" must reject a source-only version.
        mode_versions = versions_for_mode(spec, mode)
        if mode_versions != None and tag["version"] not in mode_versions:
            return ("tools.{}: version=\"{}\" is not available in mode=\"{}\". " +
                    "Versions for that mode: {}.").format(
                tag["tool"],
                tag["version"],
                mode,
                # The tables carry `a.b.x` wildcard aliases alongside their
                # exact patches; only the exact ones belong in this message.
                exact_versions(mode_versions),
            )

    return None

def validate_tag(tag):
    """Validate one tag dict; fails with a descriptive message on error.

    Thin `fail()` wrapper around the pure `tag_error`. See `tag_error` for the
    rules.

    Args:
        tag: tag dict as produced by _tag_to_dict.

    Returns:
        None on success; fails (does not return) on validation error.
    """
    err = tag_error(tag)
    if err:
        fail(err)

def spoke_plan_error(spokes):
    """Return a descriptive error string if the spoke plan collides, else None.

    Pure, like `tag_error`, so the rejection branch is unit-testable
    in-process; `extensions._init` supplies the `fail()`.

    Custom spokes are named after a slug of their target (see
    `custom_spokes._slug`), and distinct labels can slug alike. Two targets
    quietly sharing one spoke would mean silently building against the wrong
    binary, so reject the plan instead.

    Args:
        spokes: list of spoke descriptors, as `all_required_spokes` returns.

    Returns:
        An error string, or None if every custom spoke name is unambiguous.
    """
    claimed = {}
    for spoke in spokes:
        if spoke["mode"] != MODE_CUSTOM:
            continue
        repo = custom_spoke_repo(spoke["tool"], spoke["target"])
        if repo in claimed and claimed[repo] != spoke["target"]:
            return ("tools.{tool}(mode = \"custom\"): targets \"{a}\" and \"{b}\" " +
                    "both map to the spoke repo \"{repo}\". Rename one of the " +
                    "targets so the two differ by more than punctuation.").format(
                a = claimed[repo],
                b = spoke["target"],
                repo = repo,
                tool = spoke["tool"],
            )
        claimed[repo] = spoke["target"]
    return None

# ============================================================
# Spoke specification
# ============================================================

def spoke_specs_for_tag(tag):
    """Return a list of spoke descriptors that need to exist for this tag.

    Descriptor shape:
        {"tool": <str>, "version": <str>, "mode": <str>, "target": <str>}

    ``version`` is empty for the unversioned modes (system, noop, custom) and
    ``target`` is empty for every mode but custom; `tag_error` has already
    guaranteed both, so this is a straight projection.

    Args:
        tag: tag dict as produced by _tag_to_dict, already validated.

    Returns:
        A list of spoke-descriptor dicts (currently always one entry).
    """
    return [{
        "mode": tag["mode"],
        "target": tag["target"],
        "tool": tag["tool"],
        "version": tag["version"],
    }]

# ============================================================
# Hub registration plan
# ============================================================

def _binary_platform_entries(tool, version):
    """Return [(label, exec_compatible_with, target_compatible_with), ...].

    One entry per supported (os, arch) platform. The exec_compatible_with
    list is the platform's `constraints` (so toolchain resolution picks the
    right native_tool_toolchain target); binary spokes carry no extra
    target constraint.
    """
    spec = get_spec(tool)
    srcs = spec.binary_versions
    if srcs == None:
        fail("_binary_platform_entries: no binary srcs for tool \"{}\"".format(tool))
    per_plat = srcs.get(version)
    if per_plat == None:
        fail("_binary_platform_entries: no version \"{}\" for tool \"{}\"".format(version, tool))
    target = spec.binary_target
    entries = []
    for os_arch in sorted(per_plat.keys()):
        plat = per_plat[os_arch]
        repo = binary_spoke_repo(tool, version, os_arch)
        entries.append(("@{}//:{}".format(repo, target), list(plat.constraints), []))
    return entries

def _hub_targets_for(spoke):
    """Return [(label, exec_compatible_with, target_compatible_with), ...].

    Binary mode expands to one entry per supported platform. Other modes
    return a single entry. System mode carries any host constraint the tool
    declares (e.g. nmake/msbuild are Windows-only), so the hub-registered
    toolchain never resolves on a host the tool can't run on.
    """
    tool, version, mode = spoke["tool"], spoke["version"], spoke["mode"]
    if mode == MODE_BINARY:
        return _binary_platform_entries(tool, version)
    if mode in (MODE_SOURCE, MODE_CUSTOM):
        # Both name a per-tag spoke holding one native_tool_toolchain. The
        # tag's own constraints are appended by the caller, same as any other
        # mode, which is what keeps a custom entry inside the hub's precedence
        # ordering instead of standing outside it.
        if mode == MODE_SOURCE:
            repo = source_spoke_repo(tool, version)
        else:
            repo = custom_spoke_repo(tool, spoke["target"])
        return [("@{repo}//:{tool}_tool".format(repo = repo, tool = tool), [], [])]
    if mode == MODE_SYSTEM:
        spec = get_spec(tool)
        exec_compat = getattr(spec, "system_exec_compatible_with", [])
        target_compat = getattr(spec, "system_target_compatible_with", [])
        return [(
            "@rules_foreign_cc//toolchains/private:preinstalled_{}".format(tool),
            list(exec_compat),
            list(target_compat),
        )]
    if mode == MODE_NOOP:
        return [("@rules_foreign_cc//toolchains:noop_{}_toolchain".format(tool), [], [])]
    fail("unknown mode {}".format(mode))

def _has_registerable_root_tag(tagset, tool):
    """Return True iff the root has a registration-bearing tag for `tool`.

    Tags with the default ``register_toolchain = True`` register a hub
    entry and displace rfcc's defaults. Tags that explicitly opt
    out of registration (e.g. rfcc's own
    ``tools.<tool>(mode="source", register_toolchain=False)`` for
    source-spoke materialization) request a spoke fetch but should not
    displace rfcc's defaults.
    """
    for tag in tagset.root_tags[tool]:
        if tag["register_toolchain"]:
            return True
    return False

def suppress_default(tagset, tool):
    """Return True iff rfcc's default tags for `tool` should not register.

    rfcc's own default registrations (the ``default_tags`` group) are
    suppressed when the root either opted out wholesale via
    ``tools.explicit()`` or declared its own registerable tag for the tool
    (root-wins-on-conflict). Shared by ``build_hub_plan`` (which skips the
    default ``toolchain()`` entry when suppressed) and the source-pin
    validation gate in ``_init`` (a register_toolchain=False source tag only
    has to pin the default version while rfcc's defaults are actually
    registering it). Spoke materialization in ``all_required_spokes`` is NOT
    gated on this -- declaring a spoke is lazy, and rfcc use_repo()s sub-repos
    of its own default source spokes regardless of downstream suppression.

    Args:
        tagset: struct as returned by collect_tags.
        tool: tool name string (key into ALL_TOOLS).

    Returns:
        True if rfcc's defaults are suppressed for this tool.
    """
    return tagset.explicit or _has_registerable_root_tag(tagset, tool)

def build_hub_plan(tagset):
    """Compute the ordered list of hub `toolchain(...)` entries.

    Order (lex-sorted target names produce this order in `:all`):
      1. 00_framework        -- always first
      2. 10_<tool>_<index>   -- root tags, in declaration order
      3. 20_<tool>_<index>   -- rfcc's own default tags (suppressed per-tool by
                                a registerable root tag, or wholesale by
                                tools.explicit())

    Because `:all` resolves in lexicographic name order, a root `10_` entry
    always beats rfcc's `20_` default for the same tool -- root wins on
    conflict.

    Args:
        tagset: struct as returned by collect_tags.

    Returns:
        A list of dicts, each with keys:
          "name", "toolchain_type", "toolchain",
          "exec_compatible_with", "target_compatible_with".
    """
    entries = []

    # 1. Framework toolchains: one per platform mapping.
    for idx, mapping in enumerate(TOOLCHAIN_MAPPINGS):
        entries.append({
            "exec_compatible_with": list(mapping.exec_compatible_with),
            "name": "00_framework_" + _pad3(idx),
            "target_compatible_with": [],
            "toolchain": "@{}//:commands".format(mapping.repo_name),
            "toolchain_type": "@rules_foreign_cc//foreign_cc/private/framework:shell_toolchain",
        })

    # 2. Root tag registrations. Each spoke may expand into multiple hub
    # entries (binary mode emits one per platform).
    for tool in ALL_TOOLS:
        _append_tag_entries(entries, "10", tool, tagset.root_tags[tool])

    # 3. rfcc defaults. rfcc's own MODULE.bazel default tags, suppressed
    # per-tool by a registerable root tag or wholesale by tools.explicit()
    # (the suppress_default predicate, shared with all_required_spokes so a
    # registered default can't point at an unfetched spoke).
    for tool in ALL_TOOLS:
        if suppress_default(tagset, tool):
            continue
        _append_tag_entries(entries, "20", tool, tagset.default_tags[tool])

    return entries

def _append_tag_entries(entries, prefix, tool, tags):
    """Append the hub `toolchain()` entries for a tool's tags to `entries`.

    Shared by the root (`10_`) and rfcc-default (`20_`) tags so both expand a
    tag identically. Each registerable tag becomes one or more entries: binary
    mode fans out to one per supported platform, other modes emit one. The
    tag's own constraints are appended to each expansion row (for binary mode
    this narrows each per-platform row, so naming a platform that matches no
    row leaves the binary rows unresolvable -- a user error surfacing at
    toolchain resolution, since the planner can't enumerate the valid platform
    set without duplicating the spoke tables). `register_toolchain = False`
    tags are skipped (they fetch a spoke but register nothing).

    The per-tool index counts only this group's emitted tags, so names are
    `<prefix>_<tool>_<tag_index>_<platform_index>`.
    """
    spec = get_spec(tool)
    tag_index = 0
    for tag in tags:
        if not tag["register_toolchain"]:
            continue
        spoke = spoke_specs_for_tag(tag)[0]
        targets = _hub_targets_for(spoke)
        for sub_idx, (label, exec_constraints, target_constraints) in enumerate(targets):
            exec_compat = list(tag["exec_compatible_with"]) + exec_constraints
            target_compat = list(tag["target_compatible_with"]) + target_constraints
            entries.append({
                "exec_compatible_with": exec_compat,
                "name": "{}_{}_{}_{}".format(
                    prefix,
                    tool,
                    _pad3(tag_index),
                    _pad3(sub_idx),
                ),
                "target_compatible_with": target_compat,
                "toolchain": label,
                "toolchain_type": spec.toolchain_type,
            })
        tag_index += 1

def pick_source_version(tagset, tool):
    """Return the source version the hub should alias for `tool`, or None.

    Used to wire ``@rules_foreign_cc_toolchains//:<tool>_src_*`` aliases at
    a stable apparent name even when the default mode is binary. Resolution:

      1. If the root declared a *registering*
         ``tools.<tool>(mode = "source", version = V)`` tag, return V.
      2. Else, if not under ``tools.explicit()`` and ``tool``'s
         ``default_version`` exists in its source-version table, return that.
         (Handles cmake/ninja, which default to binary but ship the same
         version's source archive.)
      3. Else, return None; no alias is emitted. Under ``tools.explicit()``
         with no registering root source tag for ``tool``, downstream
         references to ``@rules_foreign_cc_toolchains//:<tool>_src_*`` will
         fail with a clear "no such target" error rather than silently
         aliasing a default version the root explicitly opted out of.

    ``register_toolchain = False`` source tags are skipped: they fetch a
    version-suffixed spoke (``@<tool>_src_<version>``) for the consumer to
    reference directly, but they register no toolchain, so they must not move
    the version-neutral hub alias off the registered default. This is what
    makes the documented Pattern B safe -- a non-default
    ``register_toolchain = False`` source pin fetches its own spoke without
    the hub alias and the default registration diverging.

    The first registering source-mode root tag wins; later ones are ignored.

    Args:
        tagset: struct as returned by collect_tags.
        tool: tool name string (key into ALL_TOOLS).

    Returns:
        A version string, or None if no source-mode version is available.
    """
    spec = get_spec(tool)
    if spec.known_versions == None:
        return None
    for tag in tagset.root_tags[tool]:
        if tag["mode"] == MODE_SOURCE and tag["version"] and tag["register_toolchain"]:
            return tag["version"]
    if tagset.explicit:
        return None
    if spec.default_version and _has_source_version(tool, spec.default_version):
        return spec.default_version
    return None

def _has_source_version(tool, version):
    """True iff `tool`'s source-archive table contains `version`.

    `known_versions` combines binary+source keys for cmake/ninja; this
    consults the tool's source table specifically (so an alias only
    resolves when a source archive actually exists). A tool with no source
    mode has `source_versions = None` and returns False.
    """
    src = get_spec(tool).source_versions
    return src != None and version in src

def all_required_spokes(tagset):
    """Return all spoke descriptors that need to be materialized.

    "Materialize" here means declare the spoke repo; declaring is lazy, so
    Bazel only downloads one when something references its targets.

    Spokes come from:
      - Every root tag (regardless of ``register_toolchain``; the spoke is
        declared either way, and ``register_toolchain`` only suppresses the hub
        entry).
      - Every non-root tag. Non-root tags declare their spoke so the
        per-version repo is reachable inside that module's scope. They never
        contribute hub registrations or singleton aliases; those remain
        root-driven. ``tools.explicit()`` does NOT suppress non-root spoke
        declaration; it gates registration and singleton aliases only.
      - The rfcc-default set for tools where root is silent (and not explicit).

    Args:
        tagset: struct as returned by collect_tags.

    Returns:
        A list of spoke descriptor dicts with keys "tool", "version", "mode"
        and "target".
    """
    out = []
    for tool in ALL_TOOLS:
        for tag in tagset.root_tags[tool]:
            out.extend(spoke_specs_for_tag(tag))
        for tag in tagset.nonroot_tags[tool]:
            out.extend(spoke_specs_for_tag(tag))

        # rfcc's default-tag spokes, for modes that need a fetched repo
        # (system/noop reference static //toolchains targets). Materialized
        # UNCONDITIONALLY, not gated on suppress_default: declaring a spoke is
        # lazy (Bazel fetches it only when referenced), and the hub aliases
        # these spokes unconditionally (see build_hub_aliases), so they must
        # exist whenever rfcc is in the graph -- even when a downstream root's
        # tools.explicit() suppresses their *registration*. Suppression gates
        # only the 20_ hub registration (build_hub_plan), never materialization.
        # Duplicates against the SOURCE_TOOLS loop below dedup in
        # extensions._init.
        for tag in tagset.default_tags[tool]:
            spoke = spoke_specs_for_tag(tag)[0]
            if spoke["mode"] in (MODE_BINARY, MODE_SOURCE, MODE_CUSTOM):
                out.append(spoke)

    # Materialize the source spoke behind every alias build_hub_aliases emits,
    # via the same pick_source_version predicate. A binary-default tool
    # (cmake/ninja) aliases @<tool>_src_<default> but its default tag fetches
    # the *binary* spoke, so without this the alias would point at an unfetched
    # repo. Sharing the predicate keeps the alias and its backing fetch from
    # drifting, the same way the default registration is tied to its
    # spoke. (Source-default tools re-request the version their default tag
    # already added; the duplicate deduplicates downstream in extensions._init.)
    for tool in SOURCE_TOOLS:
        version = pick_source_version(tagset, tool)
        if version != None:
            out.append({
                "mode": MODE_SOURCE,
                "target": "",
                "tool": tool,
                "version": version,
            })
    return out

def build_hub_aliases(tagset):
    """Compute hub-published aliases for per-version source spokes.

    The hub re-exports a stable, version-neutral name for each source-mode
    archive that any consumer's BUILD file can reach without leaking the
    pinned version into a downstream MODULE.bazel.

    Only `SOURCE_TOOLS` are covered, and only where
    `pick_source_version` finds a version -- these aliases point *into* a
    source spoke, so a tool whose source table lacks its default version (m4
    has no source mode at all; pkgconfig's table is pkg-config 0.29.2 against
    a pkgconf 3.0.7 default) publishes nothing here. A `custom`-mode tag is
    likewise invisible to this: the target it names is one the consumer
    already has a label for.

    The WORKSPACE hub (`built_toolchains._emit_workspace_hub`) additionally
    publishes a `<tool>_built` pointing straight at each registry module's
    binary. Bzlmod has never done so.

    Per source-tool aliases:

      - ``<tool>_built`` -> ``@<tool>_src_<picked>//:<tool>_built`` --
        the build-from-source macro target. Aliases forward providers,
        so consumers can read its ``script_file`` / ``wrapper_script_file``
        output groups for lint coverage.
      - ``<tool>_src_all`` -> ``@<tool>_src_<picked>//:all_srcs`` --
        the entire archive content (filegroup of upstream sources).

    For meson specifically (the only tool a public macro pokes into),
    two extra aliases:

      - ``meson_src_meson_py``  -> ``@meson_src_<picked>//:meson.py``
      - ``meson_src_runtime``   -> ``@meson_src_<picked>//:runtime``

    Args:
        tagset: struct as returned by collect_tags.

    Returns:
        A list of dicts with keys ``name`` and ``actual``. Order is
        stable (sorted by name) for deterministic BUILD-file emission.
    """
    aliases = []
    for tool in SOURCE_TOOLS:
        version = pick_source_version(tagset, tool)
        if version == None:
            continue
        aliases.extend(source_spoke_aliases(tool, version))
    return sorted(aliases, key = lambda d: d["name"])

# Re-exported for planner_test, which asserts the zero-padding width that the
# hub's lexicographic :all ordering depends on. Not part of the public API.
pad3 = _pad3
