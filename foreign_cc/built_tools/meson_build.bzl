"""Rule for building Meson from source."""

load("@rules_python//python:defs.bzl", "py_binary")
load("@rules_python//python:features.bzl", "features")

def meson_tool(name, requirements = [], **kwargs):
    """Build a Meson launcher with the rfcc compatibility wrapper.

    Args:
        name: Target name.
        requirements: Extra Python requirements Meson should inherit.
        **kwargs: Remaining `py_binary` arguments.
    """
    kwargs.pop("precompile", None)
    if not features.uses_builtin_rules:
        kwargs["precompile"] = "disabled"
    wrapper = Label("//foreign_cc/built_tools:meson_tool_wrapper.py")
    py_binary(
        name = name,
        main = "meson_tool_wrapper.py",
        srcs = kwargs.pop("srcs", []) + [wrapper],
        deps = requirements + [
            "@meson_src//:runtime",
            "@rules_python//python/runfiles",
        ],
        python_version = "PY3",
        **kwargs
    )
