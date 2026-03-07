"""# [MSBuild](#msbuild)

This rule is tailored for MSBuild.exe from the Visual Studio installation. It does not support
the dotnet msbuild execution path. MSBuild determines it own compile and linker flags based
on the project/solution file configuration. This cannot be fully controlled from bazel like
other rules (e.g. cmake). We do our best by generating a `msbuild.props` file that is used by
specifying `-p:ForceImportAfterCppTargets=msbuild.props` to append bazel flags and override
existing flags where possible.

Since MSBuild is closed source project from Microsoft, there is no prebuilt toolchain available
and we cannot build it from source. The default is a pre-installed toolchain which assumes
MSBuild.exe is installed as a part of Visual Studio and locateable by bazel. If you want to
implement your own MSBuild toolchain you will need to define a toolchain that implements the
toolchain type `@rules_foreign_cc//toolchains:msbuild_toolchain`. E.g.

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
    env = {
        "MSBUILD": "$(execpath <Label for MSBuild.exe>)",
    },
)
```

`native_tool_toolchain` should refer to the target where your MSBuild binary/files reside.

When using your own toolchain, it may also be necessary to set the following properties
for MSBuild:

```
# Use env from bazel toolchain, don't override it.
"-p:UseEnv=true",
"-p:SetEnvOverride=false",

# Toolchain config
"-p:PlatformToolset=", # e.g "v143" for Visual Studio 2022
"-p:VCToolsRedistVersion=",
"-p:VCInstallDir=<path to Visual C++ install dir>",
"-p:VCInstallDir_170=<path to Visual C++ install dir for Visual Studios 2022>",

# SDK configuration
"-p:WindowsSdkDir_10=<path to windows sdk>",
"-p:WindowsKitsRoot=<path to windows sdk>",

# Skip the problematic SDK check target
"-p:_CheckWindowsSDKInstalled=",

# Bypass Windows SDK validation checks
"-p:WindowsSDKInstalled=true",
"-p:WindowsSDK_Desktop_Support=true",
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

    data = attrs.data + attrs.build_data

    user_properties = ctx.attr.properties
    args = ctx.attr.args
    configuration = ctx.attr.configuration
    targets = ctx.attr.targets
    verbosity = ctx.attr.verbosity

    root = detect_root(attrs.lib_source)
    flags = get_flags_info(ctx)

    default_properties = {
        # We generate a props file to add our compile and linker.
        "ForceImportAfterCppTargets": "$$BUILD_TMPDIR/msbuild.props",
        "OutDir": "$$INSTALLDIR/",
        "TrackFileAccess": "false",
    }

    all_properties = default_properties | user_properties
    all_properties.update({"Configuration": configuration})

    all_args = _properties_to_args(all_properties)
    all_args.append("-v:{}".format(verbosity))
    if args:
        all_args.extend(args)
    if targets:
        all_args.append("-t:{}".format(",".join(targets)))

    expanded_args = expand_locations_and_make_variables(ctx, all_args, "args", data)

    return create_msbuild_script(
        workspace_name = ctx.workspace_name,
        flags = flags,
        root = root,
        msbuild_path = attrs.msbuild_path,
        msbuild_sln_path = ctx.attr.sln_file,
        msbuild_args = " ".join(expanded_args),
        include_dirs = inputs.include_dirs,
        ext_build_dirs = inputs.ext_build_dirs,
    )

def _attrs():
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
    attrs.update({
        "args": attr.string_list(
            doc = "Args for MSBuild.exe. e.g. '-p:PlatformToolset=v143'",
            mandatory = False,
            default = [],
        ),
        "configuration": attr.string(
            doc = "Configuration of the build. Usually either `Debug` or `Release`.",
            mandatory = False,
            default = "Release",
        ),
        "properties": attr.string_dict(
            doc = "A map of properties (`-p:`) for msbuild.",
            mandatory = False,
            default = {},
        ),
        "sln_file": attr.string(
            doc = "Path to the solution or project file for MSBuild.",
            mandatory = True,
        ),
        "targets": attr.string_list(
            doc = "List of MSBuild targets in the project",
            mandatory = False,
            default = [],
        ),
        "verbosity": attr.string(
            doc = "VerbosityLevel of msbuild logs. One of 'quiet', 'minimal', 'normal', 'detailed', 'diagnostic'.",
            mandatory = False,
            default = "normal",
            values = ["quiet", "minimal", "normal", "detailed", "diagnostic"],
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

    # Only msbuild from MSVC is supported so make it windows only.
    exec_compatible_with = ["@platforms//os:windows"],
    toolchains = [
        "@rules_foreign_cc//toolchains:msbuild_toolchain",
        "@rules_foreign_cc//foreign_cc/private/framework:shell_toolchain",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)

def _properties_to_args(properties):
    args = []
    for k, v in properties.items():
        args.append("-p:{}={}".format(k, v))
    return args
