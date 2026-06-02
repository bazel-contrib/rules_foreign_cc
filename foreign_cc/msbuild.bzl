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

```bzl
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

```bzl
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

The MSBuild `Configuration` property is controlled by the `configuration`
attribute. When left unset it follows the Bazel compilation mode, defaulting
to `Debug` under `-c dbg` and `Release` otherwise (matching the `cmake` rule).

The MSBuild `Platform` property is controlled by the `platform` attribute. It
is left unset by default so MSBuild picks the platform declared in the
solution or project file. A `.sln` only builds the `Configuration|Platform`
pairs it declares, so forcing a platform that the solution does not declare
fails with `MSB4126`; set `platform` only when the project supports it.

MSBuild projects must copy their outputs into `$(OutDir)` using the layout
declared on the rule. For example, with the default include directory and
`out_static_libs = ["mylib.lib"]`, the project should produce
`$(OutDir)mylib.lib` and copy public headers under `$(OutDir)include`.
"""

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load(
    "//foreign_cc/private:cc_toolchain_util.bzl",
    "get_flags_info",
    "is_debug_mode",
)
load("//foreign_cc/private:detect_root.bzl", "detect_root")
load(
    "//foreign_cc/private:framework.bzl",
    "CC_EXTERNAL_RULE_ATTRIBUTES",
    "CC_EXTERNAL_RULE_FRAGMENTS",
    "cc_external_rule_impl",
    "create_attrs",
    "expand_locations_and_make_variables",
    "get_foreign_cc_dep",
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
    configuration = ctx.attr.configuration or ("Debug" if is_debug_mode(ctx) else "Release")
    platform = ctx.attr.platform
    targets = ctx.attr.targets
    verbosity = ctx.attr.verbosity

    root = detect_root(attrs.lib_source)
    flags = get_flags_info(ctx)

    all_properties = _msbuild_properties(user_properties, configuration, platform)

    all_args = _properties_to_args(all_properties)
    all_args.append("-v:{}".format(verbosity))
    if args:
        all_args.extend(args)
    if targets:
        all_args.append("-t:{}".format(",".join(targets)))

    expanded_args = expand_locations_and_make_variables(ctx, all_args, "args", data)
    dep_paths = _msbuild_dep_paths(attrs.deps, inputs)

    return create_msbuild_script(
        workspace_name = ctx.workspace_name,
        flags = flags,
        root = root,
        msbuild_path = attrs.msbuild_path,
        msbuild_sln_path = _sln_file_path(
            sln_file_path = ctx.attr.sln_file_path,
            lib_source_files = attrs.lib_source.files.to_list(),
            root = root,
        ),
        msbuild_args = expanded_args,
        dep_include_dirs = dep_paths.include_dirs,
        dep_lib_dirs = dep_paths.lib_dirs,
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
            doc = (
                "MSBuild `Configuration` to build. When unset, defaults to `Debug` in " +
                "`-c dbg` compilation mode and `Release` otherwise, mirroring the `cmake` rule. " +
                "Usually either `Debug` or `Release`."
            ),
            mandatory = False,
            default = "",
        ),
        "platform": attr.string(
            doc = (
                "MSBuild `Platform` to build (e.g. `x64`, `Win32`, `ARM64`). When unset, the " +
                "`-p:Platform` flag is omitted and MSBuild selects the platform from the solution " +
                "or project file. This is deliberately not derived from the target CPU: a `.sln` " +
                "only builds `Configuration|Platform` pairs it declares, so forcing a mismatched " +
                "platform fails with MSB4126. Set this explicitly when the project supports it."
            ),
            mandatory = False,
            default = "",
        ),
        "properties": attr.string_dict(
            doc = "A map of properties (`-p:`) for MSBuild. Do not set `Configuration` or `Platform`; use the dedicated attributes instead.",
            mandatory = False,
            default = {},
        ),
        "sln_file_path": attr.string(
            doc = "Solution or project file path, relative to the detected `lib_source` root.",
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

def _msbuild_properties(user_properties, configuration, platform):
    _fail_if_reserved_property(user_properties, "Configuration", "configuration")
    _fail_if_reserved_property(user_properties, "Platform", "platform")

    properties = {
        # We generate a props file to add our compile and linker.
        "ForceImportAfterCppTargets": "$$BUILD_TMPDIR/msbuild.props",
        "OutDir": "$$INSTALLDIR/",

        # This is used for incremental builds in MSBuild, we don't want it.
        "TrackFileAccess": "false",
    } | user_properties

    properties.update({
        "Configuration": configuration,
    })

    # Only force Platform when the user asked for one. A solution only builds the
    # Configuration|Platform pairs it declares, so a mismatched -p:Platform fails
    # with MSB4126; omitting it lets MSBuild pick the solution's own platform.
    if platform:
        properties["Platform"] = platform

    return properties

def _fail_if_reserved_property(properties, property_name, attr_name):
    if property_name in properties:
        fail("MSBuild property `{}` must be set with the `{}` attribute, not `properties`.".format(property_name, attr_name))

def _sln_file_path(sln_file_path, lib_source_files, root):
    _fail_if_absolute_or_parent_relative_sln_file_path(sln_file_path)

    expected_path = root + "/" + sln_file_path
    for source_file in lib_source_files:
        if source_file.path == expected_path:
            return sln_file_path
    fail("`sln_file_path` must name a file included in `lib_source`; got `{}`.".format(sln_file_path))

def _fail_if_absolute_or_parent_relative_sln_file_path(sln_file_path):
    if sln_file_path.startswith("/") or sln_file_path.startswith("../") or sln_file_path == ".." or "/../" in sln_file_path:
        fail("`sln_file_path` must be relative to the detected `lib_source` root; got `{}`.".format(sln_file_path))

# Include and linker search paths are order-sensitive, so keep first-seen order.
def _append_dedup(values, value):
    if value not in values:
        values.append(value)

def _msbuild_dep_paths(deps, inputs):
    include_dirs = []
    lib_dirs = []

    if inputs.headers or inputs.include_dirs:
        _append_dedup(include_dirs, "$$EXT_BUILD_DEPS$$/include")
    if inputs.libs:
        _append_dedup(lib_dirs, "$$EXT_BUILD_DEPS$$/lib")

    for dep in deps:
        foreign_dep = get_foreign_cc_dep(dep)
        if not foreign_dep:
            continue
        for artifact in foreign_dep.artifacts.to_list():
            gen_dir_name = artifact.gen_dir.basename
            _append_dedup(
                include_dirs,
                "$$EXT_BUILD_DEPS$$/{}/{}".format(gen_dir_name, artifact.include_dir_name),
            )
            _append_dedup(
                lib_dirs,
                "$$EXT_BUILD_DEPS$$/{}/{}".format(gen_dir_name, artifact.lib_dir_name),
            )

    return struct(
        include_dirs = include_dirs,
        lib_dirs = lib_dirs,
    )

export_for_test = struct(
    msbuild_properties = _msbuild_properties,
    msbuild_dep_paths = _msbuild_dep_paths,
    sln_file_path = _sln_file_path,
)
