"""Unit tests for MSBuild script creation."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//foreign_cc:msbuild.bzl", "export_for_test")
load("//foreign_cc:providers.bzl", "ForeignCcArtifactInfo", "ForeignCcDepsInfo")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:cc_toolchain_util.bzl", "CxxFlagsInfo")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:msbuild_script.bzl", "create_msbuild_script")

def _inputs(headers = [], include_dirs = [], libs = []):
    return struct(
        headers = headers,
        include_dirs = include_dirs,
        libs = libs,
    )

def _foreign_dep(artifacts):
    return {
        ForeignCcDepsInfo: ForeignCcDepsInfo(artifacts = depset(artifacts)),
    }

def _artifact(gen_dir, include_dir_name = "include", lib_dir_name = "lib"):
    return ForeignCcArtifactInfo(
        gen_dir = struct(basename = gen_dir),
        bin_dir_name = "bin",
        dll_dir_name = "bin",
        include_dir_name = include_dir_name,
        lib_dir_name = lib_dir_name,
    )

def _empty_flags():
    return _flags()

def _flags(cxx = [], cxx_linker_executable = [], cxx_linker_static = []):
    return CxxFlagsInfo(
        cc = [],
        cxx = cxx,
        cxx_linker_shared = [],
        cxx_linker_static = cxx_linker_static,
        cxx_linker_executable = cxx_linker_executable,
        assemble = [],
    )

# Bazel-provided headers and include directories are exposed through the shared include root.
def _bazel_headers_and_include_dirs_test(ctx):
    env = unittest.begin(ctx)

    dep_paths = export_for_test.msbuild_dep_paths(
        [],
        _inputs(
            headers = [struct()],
            include_dirs = ["external/include"],
        ),
    )

    asserts.equals(env, ["$$EXT_BUILD_DEPS$$/include"], dep_paths.include_dirs)
    asserts.equals(env, [], dep_paths.lib_dirs)

    return unittest.end(env)

# Bazel-provided libraries are exposed through the shared library root.
def _bazel_libraries_test(ctx):
    env = unittest.begin(ctx)

    dep_paths = export_for_test.msbuild_dep_paths(
        [],
        _inputs(libs = [struct()]),
    )

    asserts.equals(env, [], dep_paths.include_dirs)
    asserts.equals(env, ["$$EXT_BUILD_DEPS$$/lib"], dep_paths.lib_dirs)

    return unittest.end(env)

# Foreign-cc artifact include and library paths are deduped while preserving first-seen order.
def _foreign_artifacts_deduped_in_order_test(ctx):
    env = unittest.begin(ctx)

    first = _artifact("first_dep", include_dir_name = "first_include", lib_dir_name = "first_lib")
    duplicate = _artifact("first_dep", include_dir_name = "first_include", lib_dir_name = "first_lib")
    second = _artifact("second_dep", include_dir_name = "second_include", lib_dir_name = "second_lib")
    dep_paths = export_for_test.msbuild_dep_paths(
        [
            _foreign_dep([first, second]),
            _foreign_dep([duplicate]),
        ],
        _inputs(),
    )

    asserts.equals(
        env,
        [
            "$$EXT_BUILD_DEPS$$/first_dep/first_include",
            "$$EXT_BUILD_DEPS$$/second_dep/second_include",
        ],
        dep_paths.include_dirs,
    )
    asserts.equals(
        env,
        [
            "$$EXT_BUILD_DEPS$$/first_dep/first_lib",
            "$$EXT_BUILD_DEPS$$/second_dep/second_lib",
        ],
        dep_paths.lib_dirs,
    )

    return unittest.end(env)

# MSBuild Configuration is controlled by its attribute
def _msbuild_properties_test(ctx):
    env = unittest.begin(ctx)

    properties = export_for_test.msbuild_properties(
        {
            "CustomProperty": "custom-value",
        },
        "Debug",
        "",
    )

    asserts.equals(env, "custom-value", properties["CustomProperty"])
    asserts.equals(env, "$$BUILD_TMPDIR/msbuild.props", properties["ForceImportAfterCppTargets"])
    asserts.equals(env, "$$INSTALLDIR/", properties["OutDir"])
    asserts.equals(env, "false", properties["TrackFileAccess"])
    asserts.equals(env, "Debug", properties["Configuration"])

    return unittest.end(env)

# An empty platform omits the Platform property entirely.
def _msbuild_properties_no_platform_test(ctx):
    env = unittest.begin(ctx)

    properties = export_for_test.msbuild_properties({}, "Release", "")

    asserts.false(env, "Platform" in properties)

    return unittest.end(env)

# A non-empty platform is emitted as the Platform property.
def _msbuild_properties_platform_test(ctx):
    env = unittest.begin(ctx)

    properties = export_for_test.msbuild_properties({}, "Release", "x64")

    asserts.equals(env, "x64", properties["Platform"])

    return unittest.end(env)

# The solution path is selected from lib_source without a separately visible file label.
def _sln_file_path_relative_to_root_test(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        "nested/project.custom",
        export_for_test.sln_file_path(
            sln_file_path = "nested/project.custom",
            lib_source_files = [
                struct(path = "external/repo/src/nested/project.custom"),
                struct(path = "external/repo/src/nested/project.vcxproj"),
            ],
            root = "external/repo/src",
        ),
    )

    return unittest.end(env)

# The generated props file serializes precomputed dependency include directories.
def _create_msbuild_script_include_dirs_test(ctx):
    env = unittest.begin(ctx)

    script = create_msbuild_script(
        workspace_name = "ws",
        root = "external/test_rule",
        flags = _empty_flags(),
        msbuild_path = "MSBuild.exe",
        msbuild_sln_path = "project.sln",
        msbuild_args = ["-p:Configuration=Release"],
        dep_include_dirs = [
            "$$EXT_BUILD_DEPS$$/include",
            "$$EXT_BUILD_DEPS$$/foreign_dep/generated/include",
        ],
        dep_lib_dirs = [],
    )

    asserts.true(
        env,
        "<AdditionalIncludeDirectories>%(AdditionalIncludeDirectories);$$EXT_BUILD_DEPS$$/include;$$EXT_BUILD_DEPS$$/foreign_dep/generated/include</AdditionalIncludeDirectories>" in script[3],
    )

    return unittest.end(env)

# The generated props file serializes precomputed dependency library directories.
def _create_msbuild_script_lib_dirs_test(ctx):
    env = unittest.begin(ctx)

    script = create_msbuild_script(
        workspace_name = "ws",
        root = "external/test_rule",
        flags = _empty_flags(),
        msbuild_path = "MSBuild.exe",
        msbuild_sln_path = "project.sln",
        msbuild_args = ["-p:Configuration=Release"],
        dep_include_dirs = [],
        dep_lib_dirs = [
            "$$EXT_BUILD_DEPS$$/lib",
            "$$EXT_BUILD_DEPS$$/foreign_dep/generated/lib",
        ],
    )

    asserts.true(
        env,
        "<AdditionalLibraryDirectories>%(AdditionalLibraryDirectories);$$EXT_BUILD_DEPS$$/lib;$$EXT_BUILD_DEPS$$/foreign_dep/generated/lib</AdditionalLibraryDirectories>" in script[3],
    )

    return unittest.end(env)

# The generated command quotes each argv word independently.
def _create_msbuild_script_command_quoting_test(ctx):
    env = unittest.begin(ctx)

    script = create_msbuild_script(
        workspace_name = "ws",
        root = "external/test_rule",
        flags = _empty_flags(),
        msbuild_path = "C:/Program Files/MSBuild/Current/Bin/MSBuild.exe",
        msbuild_sln_path = "solutions/my project.sln",
        msbuild_args = [
            "-p:ForceImportAfterCppTargets=$BUILD_TMPDIR/msbuild.props",
            "-p:VCInstallDir=C:/Program Files/Microsoft Visual Studio/VC/",
            "-p:Owner=O'Brien",
            "-p:OutDir=$INSTALLDIR/",
            "-p:Literal=$HOME",
            "-p:LiteralInstall=$INSTALLDIR_BACKUP",
            "-p:Brace=${CUSTOM_ENV}/value",
            "-p:NotCommand=$(whoami)",
            "-p:NotBacktick=`whoami`",
            "-p:NotArithmetic=$[1+2]",
            "-t:Build App",
        ],
        dep_include_dirs = [],
        dep_lib_dirs = [],
    )

    asserts.equals(
        env,
        "\"C:/Program Files/MSBuild/Current/Bin/MSBuild.exe\" \"solutions/my project.sln\" \"-p:ForceImportAfterCppTargets=$BUILD_TMPDIR/msbuild.props\" \"-p:VCInstallDir=C:/Program Files/Microsoft Visual Studio/VC/\" \"-p:Owner=O'Brien\" \"-p:OutDir=$INSTALLDIR/\" \"-p:Literal=$HOME\" \"-p:LiteralInstall=$INSTALLDIR_BACKUP\" \"-p:Brace=${CUSTOM_ENV}/value\" \"-p:NotCommand=\\$(whoami)\" \"-p:NotBacktick=\\`whoami\\`\" \"-p:NotArithmetic=\\$[1+2]\" \"-t:Build App\"",
        script[6],
    )

    return unittest.end(env)

# The generated props file XML-escapes dependency paths and toolchain flags.
def _create_msbuild_script_props_xml_escaping_test(ctx):
    env = unittest.begin(ctx)

    script = create_msbuild_script(
        workspace_name = "ws",
        root = "external/test_rule",
        flags = _flags(
            cxx = ["/DNAME=<value>", "/DAMP=a&b"],
            cxx_linker_executable = ["/DEF:\"exports.def\""],
            cxx_linker_static = ["/MACHINE:'x64'"],
        ),
        msbuild_path = "MSBuild.exe",
        msbuild_sln_path = "project.sln",
        msbuild_args = ["-p:Configuration=Release"],
        dep_include_dirs = ["$$EXT_BUILD_DEPS$$/alpha & beta/include"],
        dep_lib_dirs = ["$$EXT_BUILD_DEPS$$/alpha & beta/lib"],
    )

    asserts.true(
        env,
        "<AdditionalIncludeDirectories>%(AdditionalIncludeDirectories);$$EXT_BUILD_DEPS$$/alpha &amp; beta/include</AdditionalIncludeDirectories>" in script[3],
    )
    asserts.true(
        env,
        "<AdditionalLibraryDirectories>%(AdditionalLibraryDirectories);$$EXT_BUILD_DEPS$$/alpha &amp; beta/lib</AdditionalLibraryDirectories>" in script[3],
    )
    asserts.true(
        env,
        "<AdditionalOptions>%(AdditionalOptions) /DNAME=&lt;value&gt; /DAMP=a&amp;b</AdditionalOptions>" in script[3],
    )
    asserts.true(
        env,
        "<AdditionalOptions>%(AdditionalOptions) /DEF:&quot;exports.def&quot;</AdditionalOptions>" in script[3],
    )
    asserts.true(
        env,
        "<AdditionalOptions>%(AdditionalOptions) /MACHINE:&apos;x64&apos;</AdditionalOptions>" in script[3],
    )

    return unittest.end(env)

bazel_headers_and_include_dirs_test = unittest.make(_bazel_headers_and_include_dirs_test)
bazel_libraries_test = unittest.make(_bazel_libraries_test)
foreign_artifacts_deduped_in_order_test = unittest.make(_foreign_artifacts_deduped_in_order_test)
msbuild_properties_test = unittest.make(_msbuild_properties_test)
msbuild_properties_no_platform_test = unittest.make(_msbuild_properties_no_platform_test)
msbuild_properties_platform_test = unittest.make(_msbuild_properties_platform_test)
sln_file_path_relative_to_root_test = unittest.make(_sln_file_path_relative_to_root_test)
create_msbuild_script_include_dirs_test = unittest.make(_create_msbuild_script_include_dirs_test)
create_msbuild_script_lib_dirs_test = unittest.make(_create_msbuild_script_lib_dirs_test)
create_msbuild_script_command_quoting_test = unittest.make(_create_msbuild_script_command_quoting_test)
create_msbuild_script_props_xml_escaping_test = unittest.make(_create_msbuild_script_props_xml_escaping_test)

def msbuild_script_test_suite():
    unittest.suite(
        "msbuild_script_test_suite",
        partial.make(bazel_headers_and_include_dirs_test, size = "small"),
        partial.make(bazel_libraries_test, size = "small"),
        partial.make(foreign_artifacts_deduped_in_order_test, size = "small"),
        partial.make(msbuild_properties_test, size = "small"),
        partial.make(msbuild_properties_no_platform_test, size = "small"),
        partial.make(msbuild_properties_platform_test, size = "small"),
        partial.make(sln_file_path_relative_to_root_test, size = "small"),
        partial.make(create_msbuild_script_include_dirs_test, size = "small"),
        partial.make(create_msbuild_script_lib_dirs_test, size = "small"),
        partial.make(create_msbuild_script_command_quoting_test, size = "small"),
        partial.make(create_msbuild_script_props_xml_escaping_test, size = "small"),
    )
