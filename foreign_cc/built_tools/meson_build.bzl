""" Rule for building meson from source. """

load("@rules_python//python:defs.bzl", "py_binary")
load("@rules_python//python:features.bzl", "features")

def meson_tool(name, main, data, requirements = [], precompile = "disabled", **kwargs):
    if features.precompile:
        py_binary(
            name = name,
            srcs = [main],
            data = data,
            deps = requirements,
            precompile = precompile,
            python_version = "PY3",
            main = main,
            **kwargs
        )
    else:
        py_binary(
            name = name,
            srcs = [main],
            data = data,
            deps = requirements,
            python_version = "PY3",
            main = main,
            **kwargs
        )
