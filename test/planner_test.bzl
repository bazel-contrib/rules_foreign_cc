"""Unit tests for the pure bzlmod planner in extension_impl.bzl.

These exercise validate_tag, pick_source_version, build_hub_plan, and the
all_required_spokes <-> build_hub_plan mirrored predicate without a real
module_ctx, by constructing tag dicts and tagset structs directly (the same
shapes collect_tags produces).
"""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//foreign_cc:repositories.bzl", "DEFAULT_TOOL_VERSIONS")

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private:extension_impl.bzl",
    "all_required_spokes",
    "build_hub_aliases",
    "build_hub_plan",
    "collect_tags",
    "pad3",
    "pick_source_version",
    "tag_error",
)

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:tool_specs.bzl", "ALL_TOOLS", "get_spec")

def _tag(tool, mode = "", version = "", register_toolchain = True, exec_compatible_with = [], target_compatible_with = []):
    """Build a tag dict in the shape _tag_to_dict produces."""
    return {
        "exec_compatible_with": list(exec_compatible_with),
        "mode": mode,
        "register_toolchain": register_toolchain,
        "target_compatible_with": list(target_compatible_with),
        "tool": tool,
        "version": version,
    }

def _rfcc_defaults():
    """rfcc's own default tags, mirroring its MODULE.bazel defaults.

    One tag per tool rfcc enables by default, in the tool's default mode
    (ladder[0]) at its default version. nmake is excluded -- it shares the
    make_toolchain type and is selected only by explicit label, never
    registered by default (the same exclusion MODULE.bazel and
    PREINSTALLED_TOOLS encode). cmake and ninja get a second, system-mode
    fallback tag mirroring MODULE.bazel: their prebuilt binaries only cover
    five platforms, so the unconstrained system toolchain catches every other
    host. Derived from tool_specs so the test fixture can't drift from the
    specs it tests.
    """
    out = {}
    for tool in ALL_TOOLS:
        if tool == "nmake":
            continue
        spec = get_spec(tool)
        version = spec.default_version if spec.default_version else ""
        out[tool] = [_tag(tool, mode = spec.ladder[0], version = version)]
        if tool in ("cmake", "ninja"):
            out[tool].append(_tag(tool, mode = "system"))
    return out

def _tagset(root = {}, nonroot = {}, default = None, explicit = False):
    """Build a tagset struct in the shape collect_tags produces.

    `default` defaults to rfcc's real default tags (see `_rfcc_defaults`), so
    a bare `_tagset()` models the common "rfcc defaults present, no consumer
    tags" config. Pass `default = {}` to model a config with no defaults at all.
    """
    root_tags = {tool: list(root.get(tool, [])) for tool in ALL_TOOLS}
    nonroot_tags = {tool: list(nonroot.get(tool, [])) for tool in ALL_TOOLS}
    if default == None:
        default = _rfcc_defaults()
    default_tags = {tool: list(default.get(tool, [])) for tool in ALL_TOOLS}
    return struct(
        root_tags = root_tags,
        nonroot_tags = nonroot_tags,
        default_tags = default_tags,
        explicit = explicit,
    )

# ---------------------------------------------------------------------------
# collect_tags
# ---------------------------------------------------------------------------

def _module_tag(mode = "", version = "", register_toolchain = True):
    """A fake Bazel tag value (struct with the attrs _tag_to_dict reads)."""
    return struct(
        exec_compatible_with = [],
        mode = mode,
        register_toolchain = register_toolchain,
        target_compatible_with = [],
        version = version,
    )

def _fake_module(name, is_root, tags = {}, explicit = False):
    """A fake bazel_module object for collect_tags.

    `tags` maps tool name -> list of _module_tag structs. `mod.tags` is the
    struct collect_tags reads per-tool via getattr; `explicit` adds a non-empty
    `explicit` tag list when set.
    """
    fields = dict(tags)
    if explicit:
        fields["explicit"] = [struct()]
    return struct(name = name, is_root = is_root, tags = struct(**fields))

def _collect_tags_test(ctx):
    env = unittest.begin(ctx)

    # Three modules, one per bucket: rfcc (defaults), a root consumer, and a
    # transitive dep. collect_tags must bucket each by origin -- rfcc by name
    # (even when it would also be the root), the consumer as root, the rest as
    # nonroot.
    rfcc = _fake_module(
        "rules_foreign_cc",
        is_root = False,
        tags = {"cmake": [_module_tag(mode = "binary", version = "3.31.12")]},
    )
    consumer = _fake_module(
        "my_app",
        is_root = True,
        tags = {"cmake": [_module_tag(mode = "system")]},
        explicit = True,
    )
    dep = _fake_module(
        "some_dep",
        is_root = False,
        tags = {"make": [_module_tag(mode = "source", version = "4.4.1")]},
    )

    ts = collect_tags([rfcc, consumer, dep])

    # rfcc's tag lands in default_tags, not root_tags.
    asserts.equals(env, 1, len(ts.default_tags["cmake"]), "rfcc cmake tag must bucket as a default")
    asserts.equals(env, "binary", ts.default_tags["cmake"][0]["mode"])
    asserts.equals(env, 1, len(ts.root_tags["cmake"]), "consumer cmake tag must bucket as root")
    asserts.equals(env, "system", ts.root_tags["cmake"][0]["mode"])
    asserts.equals(env, 1, len(ts.nonroot_tags["make"]), "dep make tag must bucket as nonroot")
    asserts.equals(env, "4.4.1", ts.nonroot_tags["make"][0]["version"])

    # The root module's tools.explicit() flips the explicit flag.
    asserts.true(env, ts.explicit, "root tools.explicit() must set explicit")

    # rfcc-as-root: when rfcc is itself the root module (in-repo builds), its
    # tags are still defaults and root_tags stays empty (bucket key is the
    # module name, not is_root).
    rfcc_root = _fake_module(
        "rules_foreign_cc",
        is_root = True,
        tags = {"cmake": [_module_tag(mode = "binary", version = "3.31.12")]},
    )
    ts2 = collect_tags([rfcc_root])
    asserts.equals(env, 1, len(ts2.default_tags["cmake"]), "rfcc-as-root cmake tag must still be a default")
    asserts.equals(env, 0, len(ts2.root_tags["cmake"]), "rfcc-as-root must not populate root_tags")

    # A non-root module's explicit list does NOT set explicit (only the root's
    # does).
    dep_explicit = _fake_module("some_dep", is_root = False, tags = {}, explicit = True)
    asserts.false(
        env,
        collect_tags([dep_explicit]).explicit,
        "a non-root tools.explicit() must not set explicit",
    )

    return unittest.end(env)

# ---------------------------------------------------------------------------
# validate_tag
# ---------------------------------------------------------------------------

def _validate_tag_accepts_test(ctx):
    env = unittest.begin(ctx)

    # tag_error returns None for valid tags (it's the pure core validate_tag
    # wraps with fail()). These all validate cleanly.
    valid = [
        _tag("cmake", mode = "binary", version = "3.31.12"),
        _tag("cmake", mode = "source", version = "3.31.12"),
        _tag("cmake", mode = "system"),
        _tag("cmake", mode = "noop"),
        _tag("make", mode = "source", version = "4.4.1"),
        _tag("ninja", mode = "binary", version = "1.13.2"),
        _tag("autoconf", mode = "system"),
        # register_toolchain=False with only a mode: valid (spoke fetch
        # without registration).
        _tag("cmake", mode = "source", version = "3.31.12", register_toolchain = False),
        # Constraint-only tag: no mode, no version, but platform constraints.
        # Valid -- it constrains the default tag; spoke_specs_for_tag fills in
        # the default mode+version.
        _tag("cmake", exec_compatible_with = ["@platforms//os:linux"]),
    ]
    for tag in valid:
        asserts.equals(env, None, tag_error(tag), "expected valid: {}".format(tag))

    # The documented migration Pattern B: a plain consumer (no tools.explicit(),
    # no sibling registerable tag) pins a non-default source version with
    # register_toolchain=False to fetch its own version-suffixed spoke. This is
    # accepted: pick_source_version skips register_toolchain=False tags, so the
    # hub's version-neutral source alias stays on the registered default and the
    # spoke is fetched without any alias/registration divergence.
    asserts.equals(
        env,
        None,
        tag_error(_tag("cmake", mode = "source", version = "3.21.7", register_toolchain = False)),
        "expected valid: documented Pattern B (non-default register_toolchain=False source pin)",
    )

    return unittest.end(env)

def _validate_tag_rejects_test(ctx):
    env = unittest.begin(ctx)

    # Each of tag_error's rejection branches must fire. Asserting on a
    # distinctive substring guards against a guard being loosened or
    # reordered (which a happy-path-only test would miss).
    def _assert_rejects(tag, needle, what):
        err = tag_error(tag)
        asserts.true(env, err != None, "expected rejection: " + what)
        if err != None:
            asserts.true(
                env,
                needle in err,
                "{}: error {} missing {}".format(what, repr(err), repr(needle)),
            )

    # 1. No-op tag (no mode/version/constraints). Rejected in either
    # register_toolchain setting: True registers the default rfcc's own
    # defaults already would; False suppresses nothing and just fetches the binary
    # default redundantly.
    _assert_rejects(_tag("cmake"), "no-op tag", "bare tag")
    _assert_rejects(_tag("cmake", register_toolchain = False), "no-op tag", "bare tag register_toolchain=False")

    # 2. Unsupported mode for the tool (make has no binary mode).
    _assert_rejects(_tag("make", mode = "binary", version = "4.4.1"), "is not supported", "bad mode")

    # 3. version supplied with system/noop.
    _assert_rejects(_tag("cmake", mode = "system", version = "3.31.12"), "is not allowed with", "version+system")
    _assert_rejects(_tag("cmake", mode = "noop", version = "3.31.12"), "is not allowed with", "version+noop")

    # 4. version required but missing (binary/source, versioned tool).
    _assert_rejects(_tag("cmake", mode = "binary"), "version is required", "missing version")

    # 5. Unknown version (not in the tool's known-version table).
    _assert_rejects(_tag("cmake", mode = "binary", version = "9.9.9"), "is not supported", "unknown version")

    # 6. version on a versionless tool, with mode omitted -- must be rejected
    # even though resolve_mode would land on system (the system/noop check only
    # fires when mode is named explicitly).
    _assert_rejects(_tag("autoconf", version = "1.2.3"), "no versioned mode", "version+versionless")

    # 7. An unknown version on a register_toolchain=False source tag still
    # reports "not supported" -- a non-default source pin with
    # register_toolchain=False is now accepted (documented Pattern B), but the
    # known-version check still rejects a version that doesn't exist.
    _assert_rejects(
        _tag("cmake", mode = "source", version = "9.9.9", register_toolchain = False),
        "is not supported",
        "register_toolchain=False unknown source version",
    )

    # 8. nmake has no noop mode (it shares the make_toolchain type, so a noop
    # nmake entry would shadow real make on every platform). The rejection
    # points at tools.make(mode = "noop").
    _assert_rejects(
        _tag("nmake", mode = "noop"),
        "tools.make(mode = \"noop\")",
        "nmake noop is rejected with a pointer to make noop",
    )

    return unittest.end(env)

# ---------------------------------------------------------------------------
# pick_source_version
# ---------------------------------------------------------------------------

def _pick_source_version_test(ctx):
    env = unittest.begin(ctx)

    # Root source tag wins.
    ts = _tagset(root = {"cmake": [_tag("cmake", mode = "source", version = "3.21.7")]})
    asserts.equals(env, "3.21.7", pick_source_version(ts, "cmake"))

    # A register_toolchain=False source tag is skipped: it fetches its own
    # version-suffixed spoke but must not move the version-neutral hub alias off
    # the registered default. This is what makes the documented Pattern B safe
    # -- the alias stays on cmake's default version while the spoke is fetched.
    ts = _tagset(root = {"cmake": [
        _tag("cmake", mode = "source", version = "3.21.7", register_toolchain = False),
    ]})
    asserts.equals(env, get_spec("cmake").default_version, pick_source_version(ts, "cmake"))

    # A register_toolchain=False pin followed by a registering source tag: the
    # registering tag drives the alias (the False one is skipped, not just
    # deprioritized).
    ts = _tagset(root = {"cmake": [
        _tag("cmake", mode = "source", version = "3.21.7", register_toolchain = False),
        _tag("cmake", mode = "source", version = "3.22.6"),
    ]})
    asserts.equals(env, "3.22.6", pick_source_version(ts, "cmake"))

    # No source tag, not explicit: cmake defaults to binary but ships the
    # same version's source, so the default version is aliased.
    ts = _tagset()
    asserts.equals(env, get_spec("cmake").default_version, pick_source_version(ts, "cmake"))

    # Under explicit() with no root source tag: no alias.
    ts = _tagset(explicit = True)
    asserts.equals(env, None, pick_source_version(ts, "cmake"))

    # First source-mode root tag wins; later ones ignored.
    ts = _tagset(root = {"cmake": [
        _tag("cmake", mode = "source", version = "3.21.7"),
        _tag("cmake", mode = "source", version = "3.22.6"),
    ]})
    asserts.equals(env, "3.21.7", pick_source_version(ts, "cmake"))

    # A versionless tool never has a source version.
    asserts.equals(env, None, pick_source_version(_tagset(), "autoconf"))

    return unittest.end(env)

# ---------------------------------------------------------------------------
# build_hub_aliases
# ---------------------------------------------------------------------------

def _src_all_version(aliases, tool):
    """Pull the version out of a tool's <tool>_src_all alias target."""
    by_name = {a["name"]: a["actual"] for a in aliases}
    actual = by_name.get("{}_src_all".format(tool))
    if actual == None:
        return None

    # actual looks like "@<tool>_src_<version>//:all_srcs".
    return actual[len("@{}_src_".format(tool)):].split("//")[0]

def _build_hub_aliases_test(ctx):
    env = unittest.begin(ctx)

    # With no tags, each source tool's published aliases must point at that
    # tool's default-version spoke. This guards against the hub aliasing a
    # different version than the registered toolchain (they both flow from
    # spec.default_version, and must agree with the WORKSPACE path).
    aliases = build_hub_aliases(_tagset())
    by_name = {a["name"]: a["actual"] for a in aliases}
    for tool in ["cmake", "make", "meson", "pkgconfig"]:
        default = get_spec(tool).default_version
        asserts.equals(
            env,
            "@{tool}_src_{v}//:all_srcs".format(tool = tool, v = default),
            by_name.get("{}_src_all".format(tool)),
            "{} hub alias must point at its default-version source spoke".format(tool),
        )

    # The alias version and the registered default toolchain version must
    # agree. rfcc's default meson tag (mode=source, version=default) drives both
    # the default registration and -- via pick_source_version reading the
    # default tag's version -- the alias. A consumer source pin at a different
    # version would diverge, which validate_tag rejects for register_toolchain
    # tags; here we confirm the default config keeps them aligned.
    default = get_spec("meson").default_version
    ts = _tagset()
    aliases = build_hub_aliases(ts)
    asserts.equals(
        env,
        default,
        _src_all_version(aliases, "meson"),
        "hub alias version must match the registered default toolchain version",
    )

    # meson alone publishes two extra aliases (meson_src_meson_py /
    # meson_src_runtime) that meson_with_requirements depends on; nothing else
    # asserts they're emitted. A missing one is a silent "no such target" for
    # that macro's callers.
    names = [a["name"] for a in aliases]
    meson_default = get_spec("meson").default_version
    by_name = {a["name"]: a["actual"] for a in aliases}
    for extra in ("meson_src_meson_py", "meson_src_runtime"):
        asserts.true(env, extra in names, "missing meson hub alias " + extra)
    asserts.equals(
        env,
        "@meson_src_{}//:meson.py".format(meson_default),
        by_name.get("meson_src_meson_py"),
        "meson_src_meson_py must alias the default-version spoke's meson.py",
    )

    # The hub emits BUILD entries in alias order, so build_hub_aliases must
    # return them already sorted by name for deterministic output.
    asserts.equals(
        env,
        sorted(names),
        names,
        "build_hub_aliases must return aliases sorted by name",
    )

    return unittest.end(env)

def _aliases_are_materialized_test(ctx):
    env = unittest.begin(ctx)

    # Every source spoke build_hub_aliases points at must also be in
    # all_required_spokes -- otherwise the hub emits alias(actual=
    # "@<tool>_src_<v>//:...") backed by no fetched repo, a "no such
    # repository" at build time. The binary-default tools (cmake/ninja) are
    # the trap: their default tag fetches the *binary* spoke while the alias
    # names the *source* spoke. Check several root configs, not just the
    # default, so a future pick_source_version change can't quietly dangle.
    cases = [
        _tagset(),
        _tagset(root = {"cmake": [_tag("cmake", mode = "system")]}),
        _tagset(root = {"ninja": [_tag("ninja", mode = "binary", version = get_spec("ninja").default_version)]}),
    ]
    for ts in cases:
        # The set of source-spoke repos all_required_spokes materializes.
        materialized = {}
        for s in all_required_spokes(ts):
            if s["mode"] == "source":
                materialized["@{}_src_{}".format(s["tool"], s["version"])] = True

        # Each alias actual is "@<repo>//:<target>"; its repo must be present.
        for alias in build_hub_aliases(ts):
            repo = alias["actual"].split("//")[0]
            asserts.true(
                env,
                repo in materialized,
                "alias {} -> {} references an unmaterialized source spoke {}".format(
                    alias["name"],
                    alias["actual"],
                    repo,
                ),
            )

    return unittest.end(env)

# ---------------------------------------------------------------------------
# build_hub_plan
# ---------------------------------------------------------------------------

def _plan_names(entries):
    return [e["name"] for e in entries]

def _default_tools():
    """rfcc's default-registering tools (nmake excluded)."""
    return [tool for tool in ALL_TOOLS if tool != "nmake"]

def _build_hub_plan_test(ctx):
    env = unittest.begin(ctx)

    # Default config (rfcc defaults present, no consumer tags): framework
    # entries + a 20_<tool>_000_000 default tag for every tool rfcc enables.
    # nmake has no default tag, so it gets no entry.
    plan = build_hub_plan(_tagset())
    names = _plan_names(plan)
    asserts.true(env, "00_framework_000" in names, "framework entry missing")
    for tool in _default_tools():
        asserts.true(
            env,
            "20_{}_000_000".format(tool) in names,
            "default tag missing for " + tool,
        )
    asserts.false(
        env,
        "20_nmake_000_000" in names,
        "nmake must not get a default registration (shadows make)",
    )

    # cmake and ninja each ship a second, system-mode default tag as an
    # unconstrained fallback. It must emit a 20_<tool>_001_000 row (tag index 1)
    # that lex-sorts after the per-platform binary rows (20_<tool>_000_*), so a
    # prebuilt binary still wins wherever one exists.
    for tool in ("cmake", "ninja"):
        asserts.true(
            env,
            "20_{}_001_000".format(tool) in names,
            "system fallback row missing for " + tool,
        )
        fallback = [e for e in plan if e["name"] == "20_{}_001_000".format(tool)][0]
        asserts.equals(
            env,
            [],
            fallback["exec_compatible_with"],
            "system fallback for {} must be unconstrained".format(tool),
        )
        asserts.equals(
            env,
            "@rules_foreign_cc//toolchains/private:preinstalled_{}".format(tool),
            fallback["toolchain"],
            "system fallback for {} must point at the preinstalled toolchain".format(tool),
        )

    # A registerable root tag suppresses that tool's default tag and adds a
    # 10_ entry instead.
    plan = build_hub_plan(_tagset(root = {"cmake": [_tag("cmake", mode = "system")]}))
    names = _plan_names(plan)
    asserts.true(env, "10_cmake_000_000" in names, "root cmake entry missing")
    asserts.false(
        env,
        "20_cmake_000_000" in names,
        "default cmake tag should be suppressed by a registerable root tag",
    )

    # Other tools keep their default tag.
    asserts.true(env, "20_ninja_000_000" in names, "ninja default tag missing")

    # The whole "root wins on conflict" contract rests on lexicographic name
    # order in :all: 00_framework < 10_root < 20_default. Assert that the
    # emitted names actually sort that way (lower prefix first) and that the
    # plan is emitted already sorted, so no consumer has to re-sort it. A
    # regression in the prefix scheme (e.g. dropping a digit, or numbering root
    # higher than default) would flip precedence silently; this catches it.
    sorted_names = sorted(names)
    asserts.true(
        env,
        sorted_names.index("00_framework_000") <
        sorted_names.index("10_cmake_000_000"),
        "framework must lex-sort before root entries",
    )
    asserts.true(
        env,
        sorted_names.index("10_cmake_000_000") <
        sorted_names.index("20_ninja_000_000"),
        "root entries (10_) must lex-sort before default entries (20_) so root wins",
    )
    asserts.equals(
        env,
        sorted_names,
        names,
        "build_hub_plan must emit entries already in lexicographic name order",
    )

    # Names must also be unique: a collision would make two toolchain() rules
    # in :all share a name and Bazel would error at hub-load time, far from
    # this planner. The zero-padded prefix scheme is what keeps them distinct,
    # so pin it here where the ordering contract lives.
    asserts.equals(
        env,
        len(names),
        len({n: None for n in names}),
        "build_hub_plan must emit unique entry names",
    )

    # A root register_toolchain=False tag does NOT suppress the default tag
    # (it fetches a spoke without registering, so it can't displace the
    # default). A non-default source pin is accepted (documented Pattern B); the
    # default tag still registers cmake's binary default.
    plan = build_hub_plan(_tagset(root = {"cmake": [
        _tag("cmake", mode = "source", version = "3.21.7", register_toolchain = False),
    ]}))
    names = _plan_names(plan)
    asserts.true(
        env,
        "20_cmake_000_000" in names,
        "register_toolchain=False must not suppress the default tag",
    )

    # explicit() drops all default tags.
    plan = build_hub_plan(_tagset(root = {"cmake": [_tag("cmake", mode = "system")]}, explicit = True))
    names = _plan_names(plan)
    for tool in _default_tools():
        asserts.false(
            env,
            "20_{}_000_000".format(tool) in names,
            "explicit() must drop default tag for " + tool,
        )

    return unittest.end(env)

def _binary_platform_expansion_test(ctx):
    env = unittest.begin(ctx)

    # A binary-mode cmake tag must expand into one hub entry per supported
    # platform, each carrying that platform's exec constraints. This proves
    # the per-platform binary-spoke wiring (incl. the windows/darwin rows)
    # without fetching any archive.
    default = get_spec("cmake").default_version
    plan = build_hub_plan(_tagset(root = {"cmake": [_tag("cmake", mode = "binary", version = default)]}))
    cmake_entries = [e for e in plan if e["name"].startswith("10_cmake_")]

    # cmake ships 5 prebuilt platforms (linux x86_64/aarch64, macos universal,
    # windows x86_64/i386), so the single tag fans out to 5 entries.
    asserts.equals(
        env,
        5,
        len(cmake_entries),
        "binary cmake tag should expand to one hub entry per prebuilt platform",
    )

    # The expansion must include the non-host platforms, each pointing at its
    # platform-suffixed spoke and gated on that platform's constraints.
    all_constraints = []
    all_toolchains = []
    for e in cmake_entries:
        all_constraints.extend(e["exec_compatible_with"])
        all_toolchains.append(e["toolchain"])
    for os_constraint in ["@platforms//os:linux", "@platforms//os:macos", "@platforms//os:windows"]:
        asserts.true(
            env,
            os_constraint in all_constraints,
            "binary expansion missing a {} entry".format(os_constraint),
        )
    asserts.true(
        env,
        "@cmake-{}-windows-x86_64//:cmake_tool".format(default) in all_toolchains,
        "binary expansion missing the windows-x86_64 spoke",
    )
    asserts.true(
        env,
        "@cmake-{}-macos-universal//:cmake_tool".format(default) in all_toolchains,
        "binary expansion missing the macos-universal spoke",
    )

    # ninja spoke names follow the same normalized `<tool>-<version>-<os>-<arch>`
    # scheme as cmake; assert ninja's names too so a regression in the shared
    # binary_spoke_repo format is caught here rather than as a downstream fetch
    # failure.
    ninja_default = get_spec("ninja").default_version
    ninja_plan = build_hub_plan(_tagset(root = {"ninja": [_tag("ninja", mode = "binary", version = ninja_default)]}))
    ninja_toolchains = [
        e["toolchain"]
        for e in ninja_plan
        if e["name"].startswith("10_ninja_")
    ]
    asserts.true(
        env,
        "@ninja-{}-linux-x86_64//:ninja_tool".format(ninja_default) in ninja_toolchains,
        "binary expansion missing the ninja-<v>-linux-x86_64 spoke",
    )
    asserts.true(
        env,
        "@ninja-{}-windows-x86_64//:ninja_tool".format(ninja_default) in ninja_toolchains,
        "binary expansion missing the ninja-<v>-windows-x86_64 spoke",
    )

    return unittest.end(env)

def _multi_tag_fanout_test(ctx):
    env = unittest.begin(ctx)

    # Two registerable root tags for one tool must produce two separately
    # indexed groups: tag_index counts emitted (registerable) tags, so the
    # second registering tag is named 10_cmake_001_*. A register_toolchain=False
    # tag in between must NOT consume an index (it registers nothing), so the
    # tag after it still lands at 001, not 002. This pins _append_tag_entries's
    # increment-on-emit contract, which a single-tag config never exercises.
    cmake_default = get_spec("cmake").default_version
    plan = build_hub_plan(_tagset(root = {"cmake": [
        _tag("cmake", mode = "system"),
        _tag("cmake", mode = "source", version = "3.21.7", register_toolchain = False),
        _tag("cmake", mode = "source", version = cmake_default),
    ]}))
    names = _plan_names(plan)
    asserts.true(env, "10_cmake_000_000" in names, "first registering cmake tag missing")
    asserts.true(
        env,
        "10_cmake_001_000" in names,
        "second registering cmake tag must be index 001 (skipped tag must not consume an index)",
    )
    asserts.false(
        env,
        "10_cmake_002_000" in names,
        "a register_toolchain=False tag must not advance the tag index",
    )

    return unittest.end(env)

def _noop_mode_in_plan_test(ctx):
    env = unittest.begin(ctx)

    # A root noop tag must emit a hub entry pointing at the static
    # noop_<tool>_toolchain target (the noop branch of _hub_targets_for). Noop
    # never flows through build_hub_plan in the other tests -- they reach noop
    # only via tag_error returning None -- so the label wiring is otherwise
    # unasserted end-to-plan.
    plan = build_hub_plan(_tagset(root = {"pkgconfig": [_tag("pkgconfig", mode = "noop")]}))
    noop_entries = [e for e in plan if e["name"] == "10_pkgconfig_000_000"]
    asserts.equals(env, 1, len(noop_entries), "root noop pkgconfig tag must emit one hub entry")
    if noop_entries:
        asserts.equals(
            env,
            "@rules_foreign_cc//toolchains:noop_pkgconfig_toolchain",
            noop_entries[0]["toolchain"],
            "noop entry must point at the static noop_<tool>_toolchain target",
        )

    return unittest.end(env)

def _nmake_system_carries_windows_test(ctx):
    env = unittest.begin(ctx)

    # nmake has no default tag (it's never registered by default), so a
    # consumer reaches it via an explicit root tag. Its system toolchain must
    # still carry the Windows exec constraint so it never resolves elsewhere.
    plan = build_hub_plan(_tagset(root = {"nmake": [_tag("nmake", mode = "system")]}))
    saw_nmake = False
    for e in plan:
        if e["name"] == "10_nmake_000_000":
            saw_nmake = True
            asserts.true(
                env,
                "@platforms//os:windows" in e["exec_compatible_with"],
                "nmake system toolchain must carry the Windows exec constraint",
            )
    asserts.true(env, saw_nmake, "root nmake system tag must produce a hub entry")

    # msbuild ships as an rfcc default (system mode), so its Windows target
    # constraint must flow through the default tag.
    plan = build_hub_plan(_tagset())
    saw_msbuild = False
    for e in plan:
        if e["name"] == "20_msbuild_000_000":
            saw_msbuild = True
            asserts.true(
                env,
                "@platforms//os:windows" in e["target_compatible_with"],
                "msbuild system toolchain must carry the Windows target constraint",
            )
    asserts.true(env, saw_msbuild, "msbuild default tag must produce a hub entry")

    return unittest.end(env)

# ---------------------------------------------------------------------------
# all_required_spokes <-> build_hub_plan mirrored predicate
# ---------------------------------------------------------------------------

def _spoke_key(s):
    return (s["tool"], s["version"], s["mode"])

def _mirrored_default_predicate_test(ctx):
    env = unittest.begin(ctx)

    # The default tag fires in build_hub_plan iff there's no registerable
    # root tag and explicit is off. all_required_spokes must materialize the
    # spoke for exactly those tools, so the registered default has a repo.
    cmake_default = get_spec("cmake").default_version
    cases = [
        _tagset(),
        _tagset(root = {"cmake": [_tag("cmake", mode = "system")]}),
        _tagset(root = {"cmake": [_tag("cmake", mode = "source", version = cmake_default, register_toolchain = False)]}),
        _tagset(explicit = True),
    ]

    # Cover both binary-default (cmake/ninja) and source-default
    # (make/meson/pkgconfig) tools, so the predicate is checked for every
    # mode whose default tag materializes a spoke.
    repo_tools = ["cmake", "ninja", "make", "meson", "pkgconfig"]
    for ts in cases:
        spokes = {_spoke_key(s): True for s in all_required_spokes(ts)}

        # If a default tag is present in the plan, its default spoke (in the
        # tool's default mode) must be in all_required_spokes -- otherwise the
        # hub registers a toolchain() pointing at an unfetched repo.
        plan_names = {e["name"]: True for e in build_hub_plan(ts)}
        for tool in repo_tools:
            spec = get_spec(tool)
            mode = spec.ladder[0]
            version = spec.default_version
            has_default_tag = "20_{}_000_000".format(tool) in plan_names
            if has_default_tag:
                asserts.true(
                    env,
                    (tool, version, mode) in spokes,
                    "default tag for {} present but its spoke wasn't materialized".format(tool),
                )

    # The explicit() case above passes vacuously: under explicit() no default
    # tag emits a 20_ entry, so `has_default_tag` is always False and the body
    # is skipped. But the load-bearing claim (extension_impl.bzl:586-600) is
    # that default-tag spokes are still *materialized* under explicit() -- rfcc
    # use_repo()s sub-repos of its own default source spokes, so they must
    # exist whenever rfcc is in the graph, even though explicit() drops their
    # registration. Assert both halves directly so a materialization regression
    # can't hide behind the vacuous branch.
    ts_explicit = _tagset(explicit = True)
    plan_explicit = {e["name"]: True for e in build_hub_plan(ts_explicit)}
    spokes_explicit = {_spoke_key(s): True for s in all_required_spokes(ts_explicit)}
    for tool in repo_tools:
        spec = get_spec(tool)
        asserts.false(
            env,
            "20_{}_000_000".format(tool) in plan_explicit,
            "explicit() must drop the default registration for " + tool,
        )
        asserts.true(
            env,
            (tool, spec.default_version, spec.ladder[0]) in spokes_explicit,
            "explicit() must still materialize {}'s default spoke".format(tool),
        )

    return unittest.end(env)

def _default_versions_in_sync_test(ctx):
    env = unittest.begin(ctx)

    # The bzlmod path (tool_specs.bzl) and the WORKSPACE path
    # (repositories.bzl DEFAULT_TOOL_VERSIONS) pin the same built-tool default
    # versions in two files. If they drift, the two paths build different tool
    # versions and the hub aliases a version the WORKSPACE path never produced.
    # Assert they agree for every tool repositories.bzl pins.
    for tool, version in DEFAULT_TOOL_VERSIONS.items():
        asserts.equals(
            env,
            version,
            get_spec(tool).default_version,
            "tool_specs default_version for {} must match repositories.bzl".format(tool),
        )

    return unittest.end(env)

def _pad3_test(ctx):
    env = unittest.begin(ctx)

    # The hub's :all resolves toolchains in lexicographic name order, which
    # equals declaration order only while every index is padded to a constant
    # width. pad3 is what enforces that width, so assert the contract it
    # guarantees: a fixed 3-char string for every in-range index.
    asserts.equals(env, "000", pad3(0))
    asserts.equals(env, "007", pad3(7))
    asserts.equals(env, "042", pad3(42))
    asserts.equals(env, "999", pad3(999))
    for n in range(0, 1000):
        asserts.equals(env, 3, len(pad3(n)), "pad3 must always be 3 chars wide")

    # Constant width means string order tracks numeric order, which is the
    # whole point: 9 must sort before 10 as "009" < "010". A naive str(n)
    # would invert that ("10" < "9").
    asserts.true(env, pad3(9) < pad3(10), "pad3 must preserve numeric order as string order")
    asserts.true(env, pad3(99) < pad3(100), "pad3 must preserve numeric order across the 2->3 digit boundary")

    # The >999 case fail()s (it would invert the ordering); fail() aborts
    # evaluation and skylib's unittest can't trap it, so that branch isn't
    # exercised here. The width assertions above cover the contract that makes
    # the guard's threshold the right one.

    return unittest.end(env)

collect_tags_test = unittest.make(_collect_tags_test)
validate_tag_accepts_test = unittest.make(_validate_tag_accepts_test)
default_versions_in_sync_test = unittest.make(_default_versions_in_sync_test)
validate_tag_rejects_test = unittest.make(_validate_tag_rejects_test)
pick_source_version_test = unittest.make(_pick_source_version_test)
build_hub_aliases_test = unittest.make(_build_hub_aliases_test)
aliases_are_materialized_test = unittest.make(_aliases_are_materialized_test)
build_hub_plan_test = unittest.make(_build_hub_plan_test)
binary_platform_expansion_test = unittest.make(_binary_platform_expansion_test)
nmake_system_carries_windows_test = unittest.make(_nmake_system_carries_windows_test)
multi_tag_fanout_test = unittest.make(_multi_tag_fanout_test)
noop_mode_in_plan_test = unittest.make(_noop_mode_in_plan_test)
mirrored_default_predicate_test = unittest.make(_mirrored_default_predicate_test)
pad3_test = unittest.make(_pad3_test)

def planner_test_suite():
    unittest.suite(
        "planner_test_suite",
        partial.make(collect_tags_test, size = "small"),
        partial.make(validate_tag_accepts_test, size = "small"),
        partial.make(default_versions_in_sync_test, size = "small"),
        partial.make(validate_tag_rejects_test, size = "small"),
        partial.make(pick_source_version_test, size = "small"),
        partial.make(build_hub_aliases_test, size = "small"),
        partial.make(aliases_are_materialized_test, size = "small"),
        partial.make(build_hub_plan_test, size = "small"),
        partial.make(binary_platform_expansion_test, size = "small"),
        partial.make(nmake_system_carries_windows_test, size = "small"),
        partial.make(multi_tag_fanout_test, size = "small"),
        partial.make(noop_mode_in_plan_test, size = "small"),
        partial.make(mirrored_default_predicate_test, size = "small"),
        partial.make(pad3_test, size = "small"),
    )
