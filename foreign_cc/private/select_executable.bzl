""" a helper to work around https://github.com/bazelbuild/bazel/issues/11820 """

def _impl(ctx):
    return [DefaultInfo(files = depset([ctx.executable.src]))]

select_executable = rule(
    implementation = _impl,
    doc = "Selects just the executable from an input; workaround for https://github.com/bazelbuild/bazel/issues/11820",
    attrs = {
        "src": attr.label(
            allow_files = True,
            cfg = "exec",
            executable = True,
            mandatory = True,
            doc = "The target producing the file among other outputs",
        ),
    },
)
