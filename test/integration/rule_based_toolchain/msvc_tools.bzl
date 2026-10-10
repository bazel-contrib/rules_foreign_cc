"""Expose the host Visual C++ install to the scenario's rule-based toolchain.

rules_cc's `cc_tool` wants a file label, and rfcc needs the INCLUDE/LIB/PATH
environment that VCVARSALL.BAT produces, exactly like the autoconfigured MSVC
toolchain. This repository rule reuses rules_cc's own detection helpers (the
ones behind `@local_config_cc`) so whatever Visual Studio the autoconfigured
toolchain would find, this finds too. The `bin/` junction points at the MSVC
HostX64/x64 tool directory, so cl.exe keeps its DLLs beside it.

On non-Windows hosts the repository is a stub: empty tool files and an empty
environment. The Windows toolchain is only declared there, never selected, so
nothing ever reads the stubs.
"""

# buildifier: disable=bzl-visibility
load(
    "@rules_cc//cc/private/toolchain:windows_cc_configure.bzl",
    "find_msvc_tool",
    "find_vc_path",
    "setup_vc_env_vars",
)

_TOOLS = [
    "cl.exe",
    "lib.exe",
    "link.exe",
]

_BUILD = """\
package(default_visibility = ["//visibility:public"])

exports_files({tools})
"""

def _temp_dir(rctx):
    for var in ["TMP", "TEMP"]:
        value = rctx.os.environ.get(var)
        if value:
            return value
    return "C:\\Windows\\Temp"

def _msvc_tools_impl(rctx):
    env = {}
    if rctx.os.name.lower().startswith("windows"):
        vc_path = find_vc_path(rctx)
        if not vc_path:
            fail("Visual C++ build tools not found; set BAZEL_VC or install Visual Studio")
        cl = find_msvc_tool(rctx, vc_path, "cl.exe")
        if not cl:
            fail("cl.exe not found under %s" % vc_path)

        # find_msvc_tool returns forward slashes; let the path object do the
        # splitting rather than guessing the separator.
        bin_dir = rctx.path(cl).dirname
        for tool in _TOOLS:
            if not bin_dir.get_child(tool).exists:
                fail("%s not found in %s" % (tool, bin_dir))
        rctx.symlink(bin_dir, "bin")
        env = setup_vc_env_vars(rctx, vc_path, envvars = ["PATH", "INCLUDE", "LIB"], escape = False)
        env["TMP"] = _temp_dir(rctx)
        env["TEMP"] = env["TMP"]
    else:
        for tool in _TOOLS:
            rctx.file("bin/" + tool, "")

    rctx.file("BUILD.bazel", _BUILD.format(tools = repr(["bin/" + tool for tool in _TOOLS])))
    rctx.file("env.bzl", "MSVC_ENV = %r\n" % env)

msvc_tools = repository_rule(
    implementation = _msvc_tools_impl,
    configure = True,
    environ = [
        "BAZEL_VC",
        "BAZEL_VC_FULL_VERSION",
        "BAZEL_VS",
        "BAZEL_WINSDK_FULL_VERSION",
        "TEMP",
        "TMP",
    ],
    local = True,
)
