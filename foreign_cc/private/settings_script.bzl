"""Helpers for generating the `bazel run //foreign_cc/settings` shim."""

load("@bazel_lib//lib:expand_template.bzl", "expand_template")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")

def _render(value):
    # bazelrc accepts lowercase booleans; Starlark's str() yields "True"/"False".
    if type(value) == "bool":
        return "true" if value else "false"
    return str(value)

def _bazelrc_line(name, value):
    return "common --@rules_foreign_cc//foreign_cc/settings:{}={}".format(name, _render(value))

def settings_script(name, settings):
    """Emit a sh_binary that prints `settings` as bazelrc lines.

    Args:
        name: target name for the resulting sh_binary.
        settings: list of (sort_key, name, value) tuples. `sort_key` may be any
            comparable value (typically a tuple); entries are sorted by it
            before rendering.
    """
    lines = [
        _bazelrc_line(setting_name, value)
        for _, setting_name, value in sorted(settings, key = lambda entry: entry[0])
    ]
    expand_template(
        name = name + "_script",
        out = name + ".sh",
        template = Label("//foreign_cc/private:settings.sh.in"),
        substitutions = {
            "{{SETTINGS_BAZELRC_LINES}}": "\n".join(lines),
        },
    )
    sh_binary(
        name = name,
        srcs = [name + "_script"],
        visibility = ["//visibility:public"],
    )
