"""A module for defining WORKSPACE dependencies required for rules_foreign_cc"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//toolchains:toolchains.bzl", "built_toolchains", "prebuilt_toolchains", "preinstalled_toolchains")
load(
    "//tools/build_defs/shell_toolchain/toolchains:ws_defs.bzl",
    shell_toolchain_workspace_initalization = "workspace_part",
)

# buildifier: disable=unnamed-macro
def rules_foreign_cc_dependencies(
        native_tools_toolchains = [],
        register_default_tools = True,
        cmake_version = "3.19.6",
        make_version = "4.3",
        ninja_version = "1.10.2",
        register_preinstalled_tools = True,
        register_built_tools = True,
        additional_shell_toolchain_mappings = [],
        additional_shell_toolchain_package = None):
    """Call this function from the WORKSPACE file to initialize rules_foreign_cc \
    dependencies and let neccesary code generation happen \
    (Code generation is needed to support different variants of the C++ Starlark API.).

    Args:
        native_tools_toolchains: pass the toolchains for toolchain types
            '@rules_foreign_cc//toolchains:cmake_toolchain' and
            '@rules_foreign_cc//toolchains:ninja_toolchain' with the needed platform constraints.
            If you do not pass anything, registered default toolchains will be selected (see below).

        register_default_tools: If True, the cmake and ninja toolchains, calling corresponding
            preinstalled binaries by name (cmake, ninja) will be registered after
            'native_tools_toolchains' without any platform constraints. The default is True.

        cmake_version: The target version of the cmake toolchain if `register_default_tools`
            or `register_built_tools` is set to `True`.

        make_version: The target version of the default make toolchain if `register_built_tools`
            is set to `True`.

        ninja_version: The target version of the ninja toolchain if `register_default_tools`
            or `register_built_tools` is set to `True`.

        register_preinstalled_tools: If true, toolchains will be registered for the native built tools
            installed on the exec host

        register_built_tools: If true, toolchains that build the tools from source are registered

        additional_shell_toolchain_mappings: Mappings of the shell toolchain functions to
            execution and target platforms constraints. Similar to what defined in
            @rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:toolchain_mappings.bzl
            in the TOOLCHAIN_MAPPINGS list. Please refer to example in @rules_foreign_cc//toolchain_examples.

        additional_shell_toolchain_package: A package under which additional toolchains, referencing
            the generated data for the passed additonal_shell_toolchain_mappings, will be defined.
            This value is needed since register_toolchains() is called for these toolchains.
            Please refer to example in @rules_foreign_cc//toolchain_examples.
    """

    shell_toolchain_workspace_initalization(
        additional_shell_toolchain_mappings,
        additional_shell_toolchain_package,
    )

    native.register_toolchains(*native_tools_toolchains)

    if register_default_tools:
        prebuilt_toolchains(cmake_version, ninja_version)

    if register_built_tools:
        built_toolchains(
            cmake_version = cmake_version,
            make_version = make_version,
            ninja_version = ninja_version,
        )

    if register_preinstalled_tools:
        preinstalled_toolchains()

    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "1c531376ac7e5a180e0237938a2536de0c54d93f5c278634818e0efc952dd56c",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
        ],
    )
