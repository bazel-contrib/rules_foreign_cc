"""Small rule to summarize C/C++ toolchain tool availability."""

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

def _find_tool_in_all_files(cc_toolchain, tool_basename):
    exact_match = None
    suffix_match = None
    for tool in cc_toolchain.all_files.to_list():
        if tool.is_directory:
            continue
        if tool.basename == tool_basename:
            exact_match = tool
            break
        if tool.basename.endswith("-" + tool_basename) and suffix_match == None:
            suffix_match = tool

    if exact_match:
        return exact_match
    return suffix_match

def _tool_summary_line(name, path, artifact):
    return "{}|provider_path={}|all_files_match={}".format(
        name,
        path if path else "",
        artifact.path if artifact else "",
    )

def _cc_toolchain_probe_impl(ctx):
    cc_toolchain = find_cpp_toolchain(ctx)
    output = ctx.actions.declare_file(ctx.label.name + ".txt")

    readelf_tool = _find_tool_in_all_files(cc_toolchain, "readelf")
    otool_tool = _find_tool_in_all_files(cc_toolchain, "otool")
    dumpbin_tool = _find_tool_in_all_files(cc_toolchain, "dumpbin")
    objdump_tool = _find_tool_in_all_files(cc_toolchain, "objdump")

    lines = [
        "cpu={}".format(cc_toolchain.cpu),
        _tool_summary_line("objdump", getattr(cc_toolchain, "objdump_executable", ""), objdump_tool),
        _tool_summary_line("nm", getattr(cc_toolchain, "nm_executable", ""), _find_tool_in_all_files(cc_toolchain, "nm")),
        _tool_summary_line("strip", getattr(cc_toolchain, "strip_executable", ""), _find_tool_in_all_files(cc_toolchain, "strip")),
        _tool_summary_line("readelf", "", readelf_tool),
        _tool_summary_line("otool", "", otool_tool),
        _tool_summary_line("dumpbin", "", dumpbin_tool),
    ]

    ctx.actions.write(output = output, content = "\n".join(lines) + "\n")
    return [DefaultInfo(files = depset([output]), runfiles = ctx.runfiles(files = [output]))]

cc_toolchain_probe = rule(
    implementation = _cc_toolchain_probe_impl,
    attrs = {
        "_cc_toolchain": attr.label(
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        ),
    },
    fragments = ["cpp"],
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
)
