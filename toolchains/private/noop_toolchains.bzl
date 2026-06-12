"""Static `noop_<tool>_toolchain` targets for every tool in tool_specs.

A noop toolchain resolves cleanly at analysis time but points the tool at a
path that fails when executed. It is referenced by the hub when a root module
says `tools.<tool>(mode = "noop")`.

The point is to make the tool a no-op, not to break the build per se. Whether
the build succeeds depends on whether anything actually invokes the tool:

  * If a rule only needs the toolchain *type* to resolve (or treats the tool
    as optional and skips its work, e.g. pkgconfig set to noop to disable
    package searches), the build succeeds and that step is simply skipped.
  * If a rule actually invokes the tool, it fails loudly at execution time
    rather than silently falling back to a host binary.
"""

# This load points "up" from toolchains/ into foreign_cc/private, the reverse
# of the usual data -> specs -> planner direction. It's deliberate: noop_env is
# per-tool spec metadata that belongs in the one struct defining each tool
# (tool_specs.bzl) alongside modes/versions, not split into a separate
# toolchains-layer data file just to satisfy the layering arrow. The
# tool_specs bzl_library grants //:__subpackages__ visibility; buildifier's
# lint only inspects path layout, so suppress it here.
# buildifier: disable=bzl-visibility
load("//foreign_cc/private:tool_specs.bzl", "MODE_NOOP", "TOOL_SPECS")
load("//toolchains/native_tools:native_tools_toolchain.bzl", "native_tool_toolchain")

visibility([
    "//toolchains",
])

# `false` is a portable "always fail" sentinel: when a noop tool is actually
# invoked, the action exits non-zero and the build fails loudly. We use the
# bare name rather than an absolute path because rfcc always runs the tool
# through its generated bash script, where `false` resolves to the shell
# builtin (or a binary on PATH) on every platform rfcc supports -- including
# Windows under msys2 bash, where an absolute Unix path like /bin/false would
# not exist. noop is only meaningful when something would otherwise invoke the
# tool.
_NOOP_PATH = "false"

def define_noop_toolchains(name = "noop_toolchains"):
    """Define one `noop_<tool>_toolchain` target per noop-capable tool.

    Only tools that list MODE_NOOP in their spec get a target -- nmake is
    excluded because it shares the make_toolchain type and offers no noop mode
    (use tools.make(mode = "noop") to noop the make family). A tool whose
    noop_env dict is empty still gets a target with only a failing path:
    analysis succeeds, and invocation (if it ever happens) fails.

    Args:
      name: unused; required by buildifier's unnamed-macro lint.
    """
    _ = name  # buildifier: disable=unused-variable
    for tool, spec in TOOL_SPECS.items():
        if MODE_NOOP not in spec.modes:
            continue
        env = {k: v.replace("{NOOP_BIN}", _NOOP_PATH) for k, v in spec.noop_env.items()}
        native_tool_toolchain(
            name = "noop_{}_toolchain".format(tool),
            env = env,
            path = _NOOP_PATH,
        )
