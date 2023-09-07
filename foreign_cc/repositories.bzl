"""A module for defining WORKSPACE dependencies required for rules_foreign_cc"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//foreign_cc/private/framework:toolchain.bzl", "register_framework_toolchains")
load("//toolchains:toolchains.bzl", "built_toolchains", "prebuilt_toolchains", "preinstalled_toolchains")

# buildifier: disable=unnamed-macro
def rules_foreign_cc_dependencies(
        native_tools_toolchains = [],
        register_default_tools = True,
        cmake_version = "3.23.2",
        make_version = "4.4",
        ninja_version = "1.11.1",
        meson_version = "1.1.1",
        pkgconfig_version = "0.29.2",
        register_preinstalled_tools = True,
        register_built_tools = True,
        register_toolchains = True,
        register_built_pkgconfig_toolchain = False):
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

        meson_version: The target version of the meson toolchain if `register_built_tools` is set to `True`.

        pkgconfig_version: The target version of the pkg_config toolchain if `register_built_tools` is set to `True`.

        register_preinstalled_tools: If true, toolchains will be registered for the native built tools
            installed on the exec host

        register_built_tools: If true, toolchains that build the tools from source are registered

        register_toolchains: If true, registers the toolchains via native.register_toolchains. Used by bzlmod

        register_built_pkgconfig_toolchain: If true, the built pkgconfig toolchain will be registered. On Windows it may be preferrable to set this to False, as
            this requires the --enable_runfiles bazel option. Also note that building pkgconfig from source under bazel results in paths that are more
            than 256 characters long, which will not work on Windows unless the following options are added to the .bazelrc and symlinks are enabled in Windows.

            startup --windows_enable_symlinks -> This is required to enable symlinking to avoid long runfile paths
            build --action_env=MSYS=winsymlinks:nativestrict -> This is required to enable symlinking to avoid long runfile paths
            startup --output_user_root=C:/b  -> This is required to keep paths as short as possible
    """

    register_framework_toolchains(register_toolchains = register_toolchains)

    if register_toolchains:
        native.register_toolchains(*native_tools_toolchains)

    if register_default_tools:
        prebuilt_toolchains(cmake_version, ninja_version, register_toolchains)

    if register_built_tools:
        built_toolchains(
            cmake_version = cmake_version,
            make_version = make_version,
            ninja_version = ninja_version,
            meson_version = meson_version,
            pkgconfig_version = pkgconfig_version,
            register_toolchains = register_toolchains,
            register_built_pkgconfig_toolchain = register_built_pkgconfig_toolchain,
        )

    if register_preinstalled_tools:
        preinstalled_toolchains()

    maybe(
        http_archive,
        name = "bazel_skylib",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.2.1/bazel-skylib-1.2.1.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.2.1/bazel-skylib-1.2.1.tar.gz",
        ],
        sha256 = "f7be3474d42aae265405a592bb7da8e171919d74c16f082a5457840f06054728",
    )

    maybe(
        http_archive,
        name = "rules_python",
        sha256 = "a3a6e99f497be089f81ec082882e40246bfd435f52f4e82f37e89449b04573f6",
        strip_prefix = "rules_python-0.10.2",
        url = "https://github.com/bazelbuild/rules_python/archive/refs/tags/0.10.2.tar.gz",
    )
