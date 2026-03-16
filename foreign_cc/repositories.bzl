"""A module for defining WORKSPACE dependencies required for rules_foreign_cc"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//foreign_cc/private/framework:toolchain.bzl", "register_framework_toolchains")
load("//toolchains:toolchains.bzl", "built_toolchains", "prebuilt_toolchains", "preinstalled_toolchains")

# buildifier: disable=unnamed-macro
def rules_foreign_cc_dependencies(
        native_tools_toolchains = [],
        register_default_tools = True,
        cmake_version = "3.31.8",
        make_version = "4.4.1",
        ninja_version = "1.13.0",
        meson_version = "1.10.1",
        pkgconfig_version = "0.29.2",
        register_preinstalled_tools = True,
        register_built_tools = True,
        register_toolchains = True,
        register_built_pkgconfig_toolchain = True,
        register_repos = True):
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

        register_repos: If true, use repository rules to register the required
            dependencies. (If you are using bzlmod, you probably do not want to set
            this since it will create shadow copies of these repos)
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

    if not register_repos:
        return

    maybe(
        http_archive,
        name = "platforms",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/platforms/releases/download/1.0.0/platforms-1.0.0.tar.gz",
            "https://github.com/bazelbuild/platforms/releases/download/1.0.0/platforms-1.0.0.tar.gz",
        ],
        sha256 = "3384eb1c30762704fbe38e440204e114154086c8fc8a8c2e3e28441028c019a8",
    )

    maybe(
        http_archive,
        name = "bazel_features",
        sha256 = "2f057dd02098a106095ea291b4344257398a059eadb2c74cc470de0f9664dccd",
        strip_prefix = "bazel_features-1.28.0",
        url = "https://github.com/bazel-contrib/bazel_features/releases/download/v1.28.0/bazel_features-v1.28.0.tar.gz",
    )

    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "6e78f0e57de26801f6f564fa7c4a48dc8b36873e416257a92bbb0937eeac8446",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.8.2/bazel-skylib-1.8.2.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.8.2/bazel-skylib-1.8.2.tar.gz",
        ],
    )

    maybe(
        http_archive,
        name = "bazel_lib",
        sha256 = "e733937de2f542436c5d3d618e22c638489b40dfd251284050357babe71103d7",
        strip_prefix = "bazel-lib-3.2.0",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v3.2.0/bazel-lib-v3.2.0.tar.gz",
    )

    maybe(
        http_archive,
        name = "rules_cc",
        sha256 = "472ddca8cec1e64ad78e4f0cabbec55936a3baddbe7bef072764ca91504bd523",
        strip_prefix = "rules_cc-0.2.13",
        url = "https://github.com/bazelbuild/rules_cc/releases/download/0.2.13/rules_cc-0.2.13.tar.gz",
    )

    maybe(
        http_archive,
        name = "rules_python",
        sha256 = "098ba13578e796c00c853a2161f382647f32eb9a77099e1c88bc5299333d0d6e",
        strip_prefix = "rules_python-1.9.0",
        url = "https://github.com/bazelbuild/rules_python/releases/download/1.9.0/rules_python-1.9.0.tar.gz",
    )

    maybe(
        http_archive,
        name = "rules_shell",
        sha256 = "e6b87c89bd0b27039e3af2c5da01147452f240f75d505f5b6880874f31036307",
        strip_prefix = "rules_shell-0.6.1",
        url = "https://github.com/bazelbuild/rules_shell/releases/download/v0.6.1/rules_shell-v0.6.1.tar.gz",
    )
