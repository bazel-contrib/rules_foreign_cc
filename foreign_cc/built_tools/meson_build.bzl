""" Rule for building meson from source. """

load("@rules_python//python:defs.bzl", "py_binary")
load("@rules_python_internal//:rules_python_config.bzl", "config")

def meson_tool(name, main, data, requirements = [], **kwargs):
    kwargs.pop("precompile", None)
    if config.enable_pystar:
        kwargs["precompile"] = "disabled"
    py_binary(
        name = name,
        srcs = [main],
        data = data,
        deps = requirements,
        python_version = "PY3",
        main = main,
        **kwargs
    )
