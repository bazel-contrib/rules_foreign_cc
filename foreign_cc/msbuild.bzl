"""# [MSBuild](#msbuild)

This rule is tailored for MSBuild.exe from the Visual Studio installation. It does not support
the dotnet msbuild execution path. MSBuild determines it own compile and linker flags based
on the project/solution file configuration. This cannot be fully controlled from bazel like
other rules (e.g. cmake). We do our best by generating a `msbuild.props` file that is used by
specifying `-p:ForceImportAfterCppTargets=msbuild.props` to append bazel flags and override
existing flags where possible.

Since MSBuild is closed source project from Microsoft, there is no prebuilt toolchain available
and we cannot build it from source. The default is a pre-installed toolchain which assumes
MSBuild.exe is installed on where ever the rule is ran. If you want to implement your own MSBuild
toolchain you will need to define your own toolchain. E.g.

```
toolchain(
    name = "msbuild_toolchain",
    exec_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
    ],
    target_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
    ],
    toolchain = ":_msbuild_toolchain",
    toolchain_type = "@rules_foreign_cc//toolchains:msbuild_toolchain",
)

native_tool_toolchain(
    name = "_msbuild_toolchain",
    path = "<Path to MSBuild.exe inside target>",
    target = "<Label to toolchain target>",
)
```

"""

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("//foreign_cc/private:cc_toolchain_util.bzl", "get_flags_info")
load("//foreign_cc/private:detect_root.bzl", "detect_root")
load(
    "//foreign_cc/private:framework.bzl",
    "CC_EXTERNAL_RULE_ATTRIBUTES",
    "CC_EXTERNAL_RULE_FRAGMENTS",
    "cc_external_rule_impl",
    "create_attrs",
    "expand_locations_and_make_variables",
)
load("//foreign_cc/private:msbuild_script.bzl", "create_msbuild_script")
load("//toolchains/native_tools:tool_access.bzl", "get_msbuild_data")

def _msbuild(ctx):
    msbuild_data = get_msbuild_data(ctx)

    tools_data = [msbuild_data]

    attrs = create_attrs(
        ctx.attr,
        configure_name = "MSBuild",
        create_configure_script = _create_msbuild_script,
        tools_data = tools_data,
        msbuild_path = msbuild_data.path,
    )

    return cc_external_rule_impl(ctx, attrs)

def _create_msbuild_script(configureParameters):
    ctx = configureParameters.ctx
    attrs = configureParameters.attrs
    inputs = configureParameters.inputs

    root = detect_root(attrs.lib_source)
    flags = get_flags_info(ctx)

    data = attrs.data + attrs.build_data

    default_args = [
        "-p:TrackFileAccess=false",
        "-p:ForceImportAfterCppTargets=$$BUILD_TMPDIR/msbuild.props",
        "-p:OutDir=$$INSTALLDIR/",
    ]

    args = " ".join([
        expand_locations_and_make_variables(ctx, arg, "args", data)
        for arg in ctx.attr.args + default_args
    ])

    return create_msbuild_script(
        workspace_name = ctx.workspace_name,
        flags = flags,
        root = root,
        msbuild_path = attrs.msbuild_path,
        msbuild_sln_path = ctx.attr.sln_file,
        msbuild_args = args,
        include_dirs = inputs.include_dirs,
        ext_build_dirs = inputs.ext_build_dirs,
    )

def _attrs():
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
    attrs.update({
        "args": attr.string_list(
            doc = "Args for MSBuild.exe. e.g. '-p:Configuration=Release'",
            mandatory = False,
            default = [],
        ),
        "sln_file": attr.string(
            doc = "Path to the solution or project file for MSBuild.",
            mandatory = True,
        ),
    })
    return attrs

msbuild = rule(
    doc = "Rule for building external library with MSBuild.",
    attrs = _attrs(),
    fragments = CC_EXTERNAL_RULE_FRAGMENTS,
    output_to_genfiles = True,
    provides = [CcInfo],
    implementation = _msbuild,
    toolchains = [
        "@rules_foreign_cc//toolchains:msbuild_toolchain",
        "@rules_foreign_cc//foreign_cc/private/framework:shell_toolchain",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)
