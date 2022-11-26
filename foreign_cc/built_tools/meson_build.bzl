""" Rule for building meson from source. """

load("@rules_python//python:defs.bzl", "py_binary")

def meson_tool(name, main, data, requirements = [], **kwargs):
    py_binary(
        name = name,
        srcs = [main],
        data = data,
        deps = requirements,
        python_version = "PY3",
        main = main,
        **kwargs
    )
