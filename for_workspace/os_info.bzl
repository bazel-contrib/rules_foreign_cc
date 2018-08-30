OSInfo = provider(
    doc = "TODO",
    fields = dict(
        is_win = "",
        is_osx = "",
        is_unix = "",
    ),
)

def _os_info_impl(ctx):
    os_info = get_os_info(ctx.attr.os_name)
    out = ctx.actions.declare_file("out.txt")
    ctx.actions.write(out, str(os_info))
    return [DefaultInfo(files = depset([out])), os_info]

def get_os_info(os_name):
    is_win = os_name.find("windows") != -1
    is_osx = os_name.startswith("mac os")
    return OSInfo(
        is_unix = not is_win and not is_osx,
        is_win = is_win,
        is_osx = is_osx,
    )

_os_info = rule(
    attrs = {
        "os_name": attr.string(mandatory = True),
    },
    implementation = _os_info_impl,
)

def define_os(host_os_name):
    _os_info(
        name = "target_os",
        os_name = select({
            "@bazel_tools//src/conditions:windows": "windows",
            "@bazel_tools//src/conditions:darwin": "mac os",
            "//conditions:default": "linux",
        }),
        visibility = ["//visibility:public"],
    )
    _os_info(
        name = "host_os",
        os_name = host_os_name,
        visibility = ["//visibility:public"],
    )
