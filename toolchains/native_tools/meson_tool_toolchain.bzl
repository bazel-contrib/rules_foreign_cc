"""A meson-specific `native_tool_toolchain`.

A separate file because `native_tools_toolchain.bzl` is loaded during
WORKSPACE evaluation, before `@rules_python` exists.
"""

load("@rules_python//python:py_executable_info.bzl", "PyExecutableInfo")
load("@rules_python//python:py_info.bzl", "PyInfo")
load(":native_tools_toolchain.bzl", "ToolInfo")

MesonToolInfo = provider(
    doc = (
        "What the meson toolchain knows about the Python behind its executable. Carried as the " +
        "`meson` field of the toolchain's `ToolchainInfo`, next to the usual `data` `ToolInfo`, " +
        "which stays untouched for everything that reads toolchains generically."
    ),
    fields = {
        "interpreter": (
            "Exec-root-relative (or absolute, if preinstalled) path of the binary's own " +
            "interpreter, which its runfiles carry."
        ),
        "main": "File: the binary's entry script (`meson.py`).",
        "pythonpath": "list of string: exec-root-relative import roots of the binary's `deps`.",
    },
)

def _runfiles_path(ctx, file):
    """`file`'s path in the form `PyInfo.imports` entries use: `<repo>/<path>`."""
    if file.short_path.startswith("../"):
        return file.short_path[len("../"):]
    return "{}/{}".format(ctx.workspace_name, file.short_path)

def _import_roots(ctx, py_info):
    """`py_info.imports` as exec-root-relative directories, for PYTHONPATH.

    Import entries are runfiles-root-relative (`<repo>/<dir>`, or a bare
    `<repo>`), which does not say whether a repository's files are sources or
    generated, two different places in the exec root.
    One pass over the sources records each repository's exec-root prefix,
    preferring the source tree; a repository with no Python source falls back
    to its source-tree location. The exec root itself is returned as `.`.
    """
    imports = py_info.imports.to_list()
    if not imports:
        return []

    prefixes = {}
    for file in py_info.transitive_sources.to_list():
        repo, _, rel = _runfiles_path(ctx, file).partition("/")
        if repo not in prefixes or file.is_source:
            prefixes[repo] = file.path[:len(file.path) - len(rel)]

    roots = []
    for entry in imports:
        repo, _, sub = entry.strip("/").partition("/")
        if repo in prefixes:
            prefix = prefixes[repo]
        elif repo == ctx.workspace_name:
            prefix = ""
        else:
            prefix = "external/{}/".format(repo)
        root = (prefix + sub).rstrip("/") or "."
        if root not in roots:
            roots.append(root)
    return roots

def _interpreter(ctx, binary):
    """The binary's interpreter as `PyExecutableInfo` describes it, as an exec-root path.

    `interpreter_path` is absolute for a platform runtime, else the
    rlocationpath of an interpreter in `runfiles_without_exe`.
    """
    path = binary[PyExecutableInfo].interpreter_path
    if path.startswith("/") or (len(path) > 1 and path[1] == ":"):
        return path
    for file in binary[PyExecutableInfo].runfiles_without_exe.files.to_list():
        if _runfiles_path(ctx, file) == path:
            return file.path
    fail("{}: {} names interpreter {} but does not carry it in its runfiles".format(ctx.label, binary.label, path))

def _meson_tool_toolchain_impl(ctx):
    binary = ctx.attr.meson
    launcher = binary[DefaultInfo].files_to_run.executable
    main = binary[PyExecutableInfo].main
    interpreter = _interpreter(ctx, binary)

    return platform_common.ToolchainInfo(
        # Exec-root-relative, like every ToolInfo path; tool_access.bzl
        # absolutizes. REAL_MESON keeps its historical rlocationpath form;
        # MESON_REAL is the same file as an exec path.
        data = ToolInfo(
            env = {
                "MESON": launcher.path,
                "MESON_REAL": main.path,
                "PYTHON3": interpreter,
                "REAL_MESON": _runfiles_path(ctx, main),
            },
            path = launcher.path,
            target = binary,
            tools = [binary],
        ),
        meson = MesonToolInfo(
            interpreter = interpreter,
            main = main,
            pythonpath = _import_roots(ctx, binary[PyInfo]),
        ),
    )

meson_tool_toolchain = rule(
    doc = """\
Toolchain data for meson, given as an executable Python binary: the `@meson`
module's `py_binary`, one you declare with extra `deps`, or a binary from
another Python ruleset that provides `PyInfo` and `PyExecutableInfo`. It is
run through its own entrypoint, exactly as
`native_tool_toolchain` would run it. On top of that the toolchain exports:

- `MESON`: the executable.
- `REAL_MESON` and `MESON_REAL`: its entry script (`meson.py`) as an
  rlocationpath and as an exec path.
- `PYTHON3`: the binary's interpreter, i.e. the exec-configuration Python
  it resolved.
- `PYTHONPATH`: the binary's import roots, so every child interpreter meson
  spawns sees the same `deps`, whatever bootstrap the binary uses.

meson records `[sys.executable, meson]` at setup time and re-invokes it from
ninja, so the launcher's interpreter must stay at one path for the whole
action; the meson rule sets `RULES_PYTHON_EXTRACT_ROOT` to a per-action
directory for launchers that build their venv at run time. Register against
`@rules_foreign_cc//toolchains:meson_toolchain`.
""",
    implementation = _meson_tool_toolchain_impl,
    attrs = {
        "meson": attr.label(
            cfg = "exec",
            executable = True,
            mandatory = True,
            providers = [PyInfo, PyExecutableInfo],
            doc = "The meson Python binary, e.g. `@meson//:meson`.",
        ),
    },
)
