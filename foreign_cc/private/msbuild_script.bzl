"""A module for creating the build script for `msbuild` builds"""

load("//foreign_cc/private:make_env_vars.bzl", "join_flags_list")

def create_msbuild_script(
        workspace_name,
        root,
        flags,
        msbuild_path,
        msbuild_sln_path,
        msbuild_args,
        include_dirs = [],
        ext_build_dirs = []):
    """Constructs MSBuild script to be passed to cc_external_rule_impl.

    Args:
        workspace_name: current workspace name
        root: sources root relative to the $EXT_BUILD_ROOT
        flags: cc_toolchain flags (CxxFlagsInfo)
        msbuild_path: path to msbuild.exe.
        msbuild_sln_path: path to msbuild's solution file to be built.
        msbuild_args: msbuild arguments in a space delimited string.
        include_dirs: Optional additional include directories. Defaults to [].
        ext_build_dirs: A list of gen_dirs for each foreign_cc dep.

    Returns:
        list: Lines of bash which make up the build script.
    """
    script = []

    script.append("##symlink_contents_to_dir## $$EXT_BUILD_ROOT$$/{} $$BUILD_TMPDIR$$ False".format(root))
    script.append("##enable_tracing##")
    script.extend(["cat > msbuild.props << EOF"] + [_create_props_file_text(flags, include_dirs, ext_build_dirs, workspace_name)] + ["EOF", ""])

    msbuild_command = "\"{msbuild}\" {sln} {args}".format(
        msbuild = msbuild_path,
        sln = msbuild_sln_path,
        args = msbuild_args,
    )

    script.append(msbuild_command)
    script.append("##disable_tracing##")
    return script

def _create_props_file_text(flags, include_dirs, ext_build_dirs, workspace_name):
    props_template = """<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
    <ItemDefinitionGroup>
        <ClCompile>
            <AdditionalIncludeDirectories>%(AdditionalIncludeDirectories);{include_dirs}</AdditionalIncludeDirectories>
            <AdditionalOptions>{cxx_flags}</AdditionalOptions>
        </ClCompile>
        <Link>
            <AdditionalLibraryDirectories>%(AdditionalLibraryDirectories);{lib_dirs}</AdditionalLibraryDirectories>
            <AdditionalOptions>{linker_flags}</AdditionalOptions>
        </Link>
        <Lib>
            <AdditionalOptions>{static_linker_flags}</AdditionalOptions>
        </Lib>
    </ItemDefinitionGroup>
</Project>
"""

    return props_template.format(
        include_dirs = ";".join(["$$EXT_BUILD_DEPS$$"] + ["$$EXT_BUILD_DEPS$$/{}".format(d) for d in include_dirs]),
        lib_dirs = ";".join(["$$EXT_BUILD_DEPS$$/{}".format(d.basename) for d in ext_build_dirs]),
        cxx_flags = join_flags_list(workspace_name, flags.cxx),
        linker_flags = join_flags_list(workspace_name, flags.cxx_linker_executable),
        static_linker_flags = join_flags_list(workspace_name, flags.cxx_linker_static),
    )
