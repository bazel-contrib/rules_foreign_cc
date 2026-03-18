""" Rule for building meson from source. """

load("@rules_python//python:defs.bzl", "py_binary")
load("@rules_python//python:features.bzl", "features")

def meson_tool(name, main, data, requirements = [], **kwargs):
    kwargs.pop("precompile", None)
    if not features.uses_builtin_rules:
        kwargs["precompile"] = "disabled"
    py_binary(
        name = name,
        srcs = ["@rules_foreign_cc//foreign_cc/built_tools:meson_tool_wrapper.py"],
        data = data + [main],
        deps = requirements + ["@rules_python//python/runfiles"],
        python_version = "PY3",
        main = "@rules_foreign_cc//foreign_cc/built_tools:meson_tool_wrapper.py",
        **kwargs
    )
