"""A module for creating the build script for `msbuild` builds"""

load(":flag_utils.bzl", "join_flags_list")

def create_msbuild_script(
        workspace_name,
        root,
        flags,
        msbuild_path,
        msbuild_sln_path,
        msbuild_args,
        dep_include_dirs = [],
        dep_lib_dirs = []):
    """Constructs MSBuild script to be passed to cc_external_rule_impl.

    Args:
        workspace_name: current workspace name
        root: sources root relative to the $EXT_BUILD_ROOT
        flags: cc_toolchain flags (CxxFlagsInfo)
        msbuild_path: path to msbuild.exe.
        msbuild_sln_path: path to msbuild's solution file to be built.
        msbuild_args: msbuild arguments.
        dep_include_dirs: Optional dependency include directories. Defaults to [].
        dep_lib_dirs: Optional dependency library directories. Defaults to [].

    Returns:
        list: Lines of bash which make up the build script.
    """
    script = []

    script.append("##symlink_contents_to_dir## $$EXT_BUILD_ROOT$$/{} $$BUILD_TMPDIR$$ False".format(root))
    script.append("##enable_tracing##")
    script.extend(["cat > msbuild.props << EOF"] + [_create_props_file_text(flags, dep_include_dirs, dep_lib_dirs, workspace_name)] + ["EOF", ""])

    msbuild_command = " ".join([
        _shell_quote(arg)
        for arg in [msbuild_path, msbuild_sln_path] + msbuild_args
    ])

    script.append(msbuild_command)
    script.append("##disable_tracing##")
    return script

def _create_props_file_text(flags, dep_include_dirs, dep_lib_dirs, workspace_name):
    props_template = """<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
    <ItemDefinitionGroup>
        <ClCompile>
            <AdditionalIncludeDirectories>%(AdditionalIncludeDirectories);{include_dirs}</AdditionalIncludeDirectories>
            <AdditionalOptions>%(AdditionalOptions) {cxx_flags}</AdditionalOptions>
        </ClCompile>
        <Link>
            <AdditionalLibraryDirectories>%(AdditionalLibraryDirectories);{lib_dirs}</AdditionalLibraryDirectories>
            <AdditionalOptions>%(AdditionalOptions) {linker_flags}</AdditionalOptions>
        </Link>
        <Lib>
            <AdditionalOptions>%(AdditionalOptions) {static_linker_flags}</AdditionalOptions>
        </Lib>
    </ItemDefinitionGroup>
</Project>
"""

    return props_template.format(
        include_dirs = _xml_escape(";".join(dep_include_dirs)),
        lib_dirs = _xml_escape(";".join(dep_lib_dirs)),
        cxx_flags = _xml_escape(join_flags_list(workspace_name, flags.cxx)),
        linker_flags = _xml_escape(join_flags_list(workspace_name, flags.cxx_linker_executable)),
        static_linker_flags = _xml_escape(join_flags_list(workspace_name, flags.cxx_linker_static)),
    )

def _shell_quote(value):
    # MSBuild argv words are interpreted by bash before reaching MSBuild.exe.
    # Double-quote each word to preserve spaces while still allowing normal
    # $VAR/${VAR} expansion. Escape double-quote syntax and shell substitution
    # forms so they are passed literally to MSBuild.
    escaped = value.replace("\\", "\\\\")
    escaped = escaped.replace("\"", "\\\"")
    escaped = escaped.replace("`", "\\`")
    escaped = escaped.replace("$(", "\\$(")
    escaped = escaped.replace("$[", "\\$[")
    return "\"" + escaped + "\""

def _xml_escape(value):
    return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&apos;")
