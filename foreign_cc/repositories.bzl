"""A module for defining WORKSPACE dependencies required for rules_foreign_cc"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//foreign_cc/private/framework:toolchain.bzl", "register_framework_toolchains")
load("//toolchains:toolchains.bzl", "built_toolchains", "prebuilt_toolchains", "preinstalled_toolchains")

# buildifier: disable=unnamed-macro
def rules_foreign_cc_dependencies(
        native_tools_toolchains = [],
        register_default_tools = True,
        cmake_version = "3.22.2",
        make_version = "4.3",
        ninja_version = "1.10.2",
        register_preinstalled_tools = True,
        register_built_tools = True,
        register_toolchains = True):
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

        register_toolchains: If true, registers the toolchains via native.register_toolchains. Used by bzlmod
    """

    register_framework_toolchains(register_toolchains = register_toolchains)

    if register_toolchains:
        native.register_toolchains(*native_tools_toolchains)

        native.register_toolchains(
            "@rules_foreign_cc//toolchains:preinstalled_autoconf_toolchain",
            "@rules_foreign_cc//toolchains:preinstalled_automake_toolchain",
            "@rules_foreign_cc//toolchains:preinstalled_m4_toolchain",
            "@rules_foreign_cc//toolchains:preinstalled_pkgconfig_toolchain",
        )

    if register_default_tools:
        prebuilt_toolchains(cmake_version, ninja_version, register_toolchains)

    if register_built_tools:
        built_toolchains(
            cmake_version = cmake_version,
            make_version = make_version,
            ninja_version = ninja_version,
            register_toolchains = register_toolchains,
        )

    if register_preinstalled_tools:
        preinstalled_toolchains()

    maybe(
        http_archive,
        name = "bazel_skylib",
        # `main` as of 2021-10-27
        # Release request: https://github.com/bazelbuild/bazel-skylib/issues/336
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/archive/6e30a77347071ab22ce346b6d20cf8912919f644.zip",
        ],
        strip_prefix = "bazel-skylib-6e30a77347071ab22ce346b6d20cf8912919f644",
        sha256 = "247361e64b2a85b40cb45b9c071e42433467c6c87546270cbe2672eb9f317b5a",
    )
