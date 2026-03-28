""" Rule for building meson from source. """

load("@aspect_rules_py//py:defs.bzl", "py_binary")

def meson_tool(name, main, data, requirements = [], **kwargs):
    kwargs.pop("precompile", None)
    py_binary(
        name = name,
        srcs = [main],
        data = data,
        deps = requirements,
        main = main,
        **kwargs
    )
