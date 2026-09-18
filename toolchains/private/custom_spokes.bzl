"""Per-tag spoke helper for `mode = "custom"`.

Internal: loaded by the bzlmod planner. `custom` is bzlmod-only, so there is no
WORKSPACE counterpart to keep in step here.

Each helper materializes one repo per `(tool, target)`, named
`@<tool>_custom_<slug of target>`. Unlike the source and binary spokes this
fetches nothing -- the target already exists in the consumer's build -- so the
repo is pure generated BUILD text:

  * `:<alias>`: an alias onto the tag's `target`, named what the tool has to be
    called (the spec's `custom_alias_name`).
  * `:<tool>_tool`: the `native_tool_toolchain` the hub's `toolchain()` points
    at, wiring the tool's one environment variable to that alias.

The `toolchain()` itself lives in the hub, not here, which is what keeps a
custom tag inside the hub's zero-padded precedence ordering and is where the
tag's `exec_compatible_with` / `target_compatible_with` land. Both default to
empty.
"""

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:tool_specs.bzl", "get_spec")
load("//toolchains/private:hub.bzl", "hub_repo")

visibility([
    "//foreign_cc",
    "//foreign_cc/private",
    "//toolchains",
    "//toolchains/private",
])

# Mirrors SOURCE_SPOKE_REPO_FORMAT's role for source spokes: the repo creator
# below and the planner's hub target (extension_impl.bzl) both route through
# custom_spoke_repo so the two can't drift.
CUSTOM_SPOKE_REPO_FORMAT = "{tool}_custom_{slug}"

# Everything Bazel accepts in a repo name. `_` is deliberately absent: it is
# the separator _slug substitutes in, so treating it as safe would let
# `@a_b//:c` and `@a//:b_c` slug alike.
_REPO_NAME_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-."

def _slug(target):
    """Collapse a label into something usable as a repo name.

    A canonical `pkgconf+//:pkg-config` becomes `pkgconf_pkg-config`: each run
    of characters a repo name can't hold turns into a single `_`, and leading
    and trailing runs are dropped. Distinct labels can still collide (see
    `_REPO_NAME_CHARS`); `spoke_plan_error` catches that rather than letting
    two tools quietly share a spoke.
    """
    out = []
    pending_sep = False
    for c in target.elems():
        if c in _REPO_NAME_CHARS:
            if pending_sep and out:
                out.append("_")
            out.append(c)
            pending_sep = False
        else:
            pending_sep = True
    return "".join(out)

def custom_spoke_repo(tool, target):
    """Return the repo name for a `custom` spoke.

    Keyed on the target rather than on the tag's position, so the planner's hub
    entry and the materialization step derive the same name independently, and
    so two tags naming the same target share one repo.

    Args:
        tool: tool name string (key into `ALL_TOOLS`).
        target: canonical label string of the executable to wrap.

    Returns:
        The repo name as a string.
    """
    return CUSTOM_SPOKE_REPO_FORMAT.format(tool = tool, slug = _slug(target))

def _native_tool_spec(spec, tool, alias):
    """The `native_tool_toolchain` for one custom spoke, as a spec dict."""
    local = ":{}".format(alias)
    if spec.custom_launcher:
        # `target` is the launcher so `path` resolves to it; the real binary
        # rides along in `tools` so $(execpath) can still name it.
        return {
            "env": {
                spec.custom_env_var: "$(execpath {})".format(spec.custom_launcher),
                "REAL_{}".format(spec.custom_env_var): "$(execpath {})".format(local),
            },
            "name": "{}_tool".format(tool),
            "path": "$(execpath {})".format(spec.custom_launcher),
            "target": spec.custom_launcher,
            "tools": [local],
        }
    return {
        "env": {spec.custom_env_var: "$(execpath {})".format(local)},
        "name": "{}_tool".format(tool),
        "path": "$(execpath {})".format(local),
        "target": local,
    }

# buildifier: disable=unnamed-macro
def custom_spokes(tool, target):
    """Define the `@<tool>_custom_<slug>` repo wrapping one user target.

    Args:
        tool: tool name string (key into `ALL_TOOLS`).
        target: canonical label string of the executable to wrap.
    """
    spec = get_spec(tool)
    alias = spec.custom_alias_name
    hub_repo(
        name = custom_spoke_repo(tool, target),
        alias_specs_json_list = [json.encode({
            "actual": target,
            "name": alias,
        })],
        native_tool_specs_json_list = [
            json.encode(_native_tool_spec(spec, tool, alias)),
        ],
    )
