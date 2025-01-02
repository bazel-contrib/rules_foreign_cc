""" Rule for building meson from source. """

load("@bazel_features//features.bzl", "bazel_features")
load("@rules_python//python:defs.bzl", "py_binary")

def meson_tool(name, main, data, requirements = [], **kwargs):
    kwargs.pop("precompile", None)
    if bazel_features.external_deps.is_bzlmod_enabled:
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
