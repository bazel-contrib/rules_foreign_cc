"""A module for defining WORKSPACE dependencies required for rules_foreign_cc"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//foreign_cc/private/framework:toolchain.bzl", "register_framework_toolchains")
load("//toolchains:toolchains.bzl", "built_toolchains", "prebuilt_toolchains", "preinstalled_toolchains")

# buildifier: disable=bzl-visibility
load("//toolchains/private:bcr_repos.bzl", "bcr_repos")

# buildifier: disable=bzl-visibility
load("//toolchains/private:source_spokes.bzl", "pkgconfig_msvc_companions")

# Default built-tool versions for the WORKSPACE path. The bzlmod path reads the
# same defaults from tool_specs.bzl (TOOL_SPECS[t].default_version); a unit test
# (default_versions_in_sync_test) asserts the two agree so the two never build
# different tool versions.
DEFAULT_TOOL_VERSIONS = {
    "cmake": "3.31.12",
    "m4": "1.4.21",
    "make": "4.4.1",
    "meson": "1.10.1",
    "ninja": "1.13.2",
    "pkgconfig": "3.0.7",
}

# buildifier: disable=unnamed-macro
def rules_foreign_cc_dependencies(
        native_tools_toolchains = [],
        register_default_tools = True,
        cmake_version = DEFAULT_TOOL_VERSIONS["cmake"],
        m4_version = DEFAULT_TOOL_VERSIONS["m4"],
        make_version = DEFAULT_TOOL_VERSIONS["make"],
        ninja_version = DEFAULT_TOOL_VERSIONS["ninja"],
        meson_version = DEFAULT_TOOL_VERSIONS["meson"],
        pkgconfig_version = DEFAULT_TOOL_VERSIONS["pkgconfig"],
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

        m4_version: The target version of the default m4 toolchain. Selects
            which Bazel Central Registry `m4` module is fetched, so it applies
            whenever `register_repos` is `True`, not only to the built
            toolchain.

        make_version: The target version of the default make toolchain. Selects
            which Bazel Central Registry `make` module is fetched, so it applies
            whenever `register_repos` is `True`, not only to the built toolchain.

        ninja_version: The target version of the ninja toolchain if `register_default_tools`
            or `register_built_tools` is set to `True`. Also selects the Bazel
            Central Registry `ninja` module the source-built toolchain uses,
            whose versions do not all coincide with the prebuilt ones.

        meson_version: The target version of the default meson toolchain. Selects
            which Bazel Central Registry `meson` module is fetched, so it applies
            whenever `register_repos` is `True`, not only to the built toolchain.

        pkgconfig_version: The target version of the default pkg-config
            toolchain. Selects which Bazel Central Registry `pkgconf` module is
            fetched, so it applies whenever `register_repos` is `True`, not
            only to the built toolchain.

        register_preinstalled_tools: If true, toolchains will be registered for the native built tools
            installed on the exec host

        register_built_tools: If true, toolchains that build the tools from source are registered

        register_toolchains: If true, registers the toolchains via native.register_toolchains. Used by bzlmod

        register_built_pkgconfig_toolchain: If true, the built pkgconfig toolchain will be registered.
            Set it to False to fall back to a host-installed pkg-config. The
            Windows caveats this flag used to carry -- --enable_runfiles, and
            the >256-character paths of the old from-source build -- no longer
            apply: pkg-config is now the `pkgconf` registry module's cc_binary.

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
            m4_version = m4_version,
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

    # 1.47.1 is rules_cc_autoconf's floor (see bcr_modules.bzl), which MVS
    # raises rfcc to under bzlmod. Pinned here for parity.
    maybe(
        http_archive,
        name = "bazel_features",
        sha256 = "6a727a78c0134b1b912c97c0937e1c956f35775934ae3e1f4af4156f8d5d1ff4",
        strip_prefix = "bazel_features-1.47.1",
        url = "https://github.com/bazel-contrib/bazel_features/releases/download/v1.47.1/bazel_features-v1.47.1.tar.gz",
    )

    # 1.9.2 is pkgconf's floor. Same reasoning as above.
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "37cdfbc6faefea94f7b37760a305c98c08981116c2bc9e821e3b423221fad8c8",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.9.2/bazel-skylib-1.9.2.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.9.2/bazel-skylib-1.9.2.tar.gz",
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
        sha256 = "1de5b47721fce0af0dd453b3071228fdfc44bd18199826b3f0b03b423aae9f65",
        strip_prefix = "rules_cc-0.2.18",
        url = "https://github.com/bazelbuild/rules_cc/releases/download/0.2.18/rules_cc-0.2.18.tar.gz",
    )

    maybe(
        http_archive,
        name = "rules_python",
        sha256 = "098ba13578e796c00c853a2161f382647f32eb9a77099e1c88bc5299333d0d6e",
        strip_prefix = "rules_python-1.9.0",
        url = "https://github.com/bazel-contrib/rules_python/releases/download/1.9.0/rules_python-1.9.0.tar.gz",
    )

    maybe(
        http_archive,
        name = "rules_shell",
        sha256 = "e6b87c89bd0b27039e3af2c5da01147452f240f75d505f5b6880874f31036307",
        strip_prefix = "rules_shell-0.6.1",
        url = "https://github.com/bazelbuild/rules_shell/releases/download/v0.6.1/rules_shell-v0.6.1.tar.gz",
    )

    # Declared, never built by rfcc: the glib archives the public
    # `pkgconfig_tool` macro names on Windows. See pkgconfig_msvc_companions.
    pkgconfig_msvc_companions()

    # @m4, @make, @ninja and @pkgconf (plus the closure their BUILD files need),
    # reconstructed from the Bazel Central Registry the way bzlmod would
    # resolve them, at the versions this call asked for.
    bcr_repos(
        m4_version = m4_version,
        make_version = make_version,
        meson_version = meson_version,
        ninja_version = ninja_version,
        pkgconfig_version = pkgconfig_version,
    )

    # rules_cc_autoconf's own MODULE.bazel registers this; WORKSPACE has to.
    # m4's, make's and pkgconf's BUILD files run their configure checks
    # through it.
    #
    # Also gated on register_built_tools: unlike an http_archive declaration, a
    # *registered* toolchain label is fetched and configured before any
    # toolchain resolution completes, so this costs ~60 MB / >10k files on the
    # first build. A consumer who opted out of source-built tools never builds
    # make and should not pay for it.
    if register_toolchains and register_built_tools:
        native.register_toolchains("@rules_cc_autoconf//gnulib/toolchain")
