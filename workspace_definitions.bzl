"""A module for defining WORKSPACE dependencies required for rules_foreign_cc"""

load("//for_workspace:repositories.bzl", "repositories")
load("//toolchains:toolchains.bzl", "prebuilt_toolchains", "preinstalled_toolchains")
load(
    "//tools/build_defs/shell_toolchain/toolchains:ws_defs.bzl",
    shell_toolchain_workspace_initalization = "workspace_part",
)

# buildifier: disable=unnamed-macro
def rules_foreign_cc_dependencies(
        native_tools_toolchains = [],
        register_default_tools = True,
        cmake_version = "3.19.5",
        ninja_version = "1.10.2",
        register_preinstalled_tools = True,
        additional_shell_toolchain_mappings = [],
        additional_shell_toolchain_package = None):
    """Call this function from the WORKSPACE file to initialize rules_foreign_cc \
    dependencies and let neccesary code generation happen \
    (Code generation is needed to support different variants of the C++ Starlark API.).

    Args:
        native_tools_toolchains: pass the toolchains for toolchain types
            '@rules_foreign_cc//tools/build_defs:cmake_toolchain' and
            '@rules_foreign_cc//tools/build_defs:ninja_toolchain' with the needed platform constraints.
            If you do not pass anything, registered default toolchains will be selected (see below).

        register_default_tools: If True, the cmake and ninja toolchains, calling corresponding
            preinstalled binaries by name (cmake, ninja) will be registered after
            'native_tools_toolchains' without any platform constraints. The default is True.

        cmake_version: The target version of the default cmake toolchain if `register_default_tools`
            is set to `True`.

        ninja_version: The target version of the default ninja toolchain if `register_default_tools`
            is set to `True`.

        register_preinstalled_tools: If true, toolchains will be registered for the native built tools
            installed on the exec host

        additional_shell_toolchain_mappings: Mappings of the shell toolchain functions to
            execution and target platforms constraints. Similar to what defined in
            @rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:toolchain_mappings.bzl
            in the TOOLCHAIN_MAPPINGS list. Please refer to example in @rules_foreign_cc//toolchain_examples.

        additional_shell_toolchain_package: A package under which additional toolchains, referencing
            the generated data for the passed additonal_shell_toolchain_mappings, will be defined.
            This value is needed since register_toolchains() is called for these toolchains.
            Please refer to example in @rules_foreign_cc//toolchain_examples.
    """
    repositories()

    shell_toolchain_workspace_initalization(
        additional_shell_toolchain_mappings,
        additional_shell_toolchain_package,
    )

    native.register_toolchains(*native_tools_toolchains)

    if register_default_tools:
        prebuilt_toolchains(cmake_version, ninja_version)

    if register_preinstalled_tools:
        preinstalled_toolchains()
