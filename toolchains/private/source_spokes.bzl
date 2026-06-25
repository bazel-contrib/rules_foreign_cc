"""Per-version source-mode spoke helpers.

Internal: load via the WORKSPACE shim in ``toolchains/built_toolchains.bzl``
or via the bzlmod planner.

Each helper materializes one repo per ``(tool, version)`` named
``@<tool>_src_<version>``. The repo's BUILD file embeds:

  * ``:all_srcs``: filegroup of upstream archive content.
  * ``:<tool>_built``: the build-from-source macro target.
  * ``:<tool>_tool``: the ``native_tool_toolchain`` referenced from the hub.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//toolchains/private:cmake_versions.bzl", "CMAKE_SRC_SRCS")
load("//toolchains/private:make_versions.bzl", "GNUMAKE_SRCS")
load("//toolchains/private:meson_versions.bzl", "MESON_SRCS")
load("//toolchains/private:ninja_versions.bzl", "NINJA_SRC_SRCS")
load("//toolchains/private:pkgconfig_versions.bzl", "PKGCONFIG_SRCS")

visibility([
    "//foreign_cc",
    "//foreign_cc/private",
    "//toolchains",
    "//toolchains/private",
])

# Single source of truth for the source-mode spoke repo name. The repo creator
# (below), the hub alias shape (hub.bzl), and the planner's hub target
# (extension_impl.bzl) all route through source_spoke_repo so the separator
# can't drift between the repo that gets minted and the label that points at
# it. Mirrors the role of the generated <TOOL>_BIN_REPO_FORMAT for binaries.
SOURCE_SPOKE_REPO_FORMAT = "{tool}_src_{version}"

def source_spoke_repo(tool, version):
    """Return the repo name for a source-mode ``(tool, version)`` spoke."""
    return SOURCE_SPOKE_REPO_FORMAT.format(tool = tool, version = version)

_CMAKE_SRC_BUILD_FILE = """\
load("@rules_foreign_cc//foreign_cc/built_tools:cmake_build.bzl", "cmake_tool")
load("@rules_foreign_cc//toolchains/native_tools:native_tools_toolchain.bzl", "native_tool_toolchain")

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "all_srcs",
    srcs = glob(["**"]),
)

cmake_tool(
    name = "cmake_built",
    srcs = ":all_srcs",
    resource_size = "enormous",
    tags = ["manual"],
)

native_tool_toolchain(
    name = "cmake_tool",
    env = select({
        "@platforms//os:windows": {"CMAKE": "$(execpath :cmake_built)/bin/cmake.exe"},
        "//conditions:default": {"CMAKE": "$(execpath :cmake_built)/bin/cmake"},
    }),
    path = select({
        "@platforms//os:windows": "$(execpath :cmake_built)/bin/cmake.exe",
        "//conditions:default": "$(execpath :cmake_built)/bin/cmake",
    }),
    target = ":cmake_built",
)

toolchain(
    name = "cmake_toolchain",
    toolchain = ":cmake_tool",
    toolchain_type = "@rules_foreign_cc//toolchains:cmake_toolchain",
)
"""

_MAKE_SRC_BUILD_FILE = """\
load("@rules_foreign_cc//foreign_cc/built_tools:make_build.bzl", "make_tool")
load("@rules_foreign_cc//toolchains/native_tools:native_tools_toolchain.bzl", "native_tool_toolchain")

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "all_srcs",
    srcs = glob(["**"]),
)

make_tool(
    name = "make_built",
    srcs = ":all_srcs",
    resource_size = "small",
    tags = ["manual"],
)

native_tool_toolchain(
    name = "make_tool",
    env = select({
        "@platforms//os:windows": {"MAKE": "$(execpath :make_built)/bin/make.exe"},
        "//conditions:default": {"MAKE": "$(execpath :make_built)/bin/make"},
    }),
    path = select({
        "@platforms//os:windows": "$(execpath :make_built)/bin/make.exe",
        "//conditions:default": "$(execpath :make_built)/bin/make",
    }),
    target = ":make_built",
)

toolchain(
    name = "make_toolchain",
    toolchain = ":make_tool",
    toolchain_type = "@rules_foreign_cc//toolchains:make_toolchain",
)
"""

_NINJA_SRC_BUILD_FILE = """\
load("@rules_foreign_cc//foreign_cc/built_tools:ninja_build.bzl", "ninja_tool")
load("@rules_foreign_cc//toolchains/native_tools:native_tools_toolchain.bzl", "native_tool_toolchain")

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "all_srcs",
    srcs = glob(["**"]),
)

ninja_tool(
    name = "ninja_built",
    srcs = ":all_srcs",
    resource_size = "small",
    tags = ["manual"],
)

native_tool_toolchain(
    name = "ninja_tool",
    env = {
        "NINJA": "$(execpath @rules_foreign_cc//toolchains/private:ninja_wrapper)",
    } | select({
        "@platforms//os:windows": {"REAL_NINJA": "$(execpath :ninja_built)/bin/ninja.exe"},
        "//conditions:default": {"REAL_NINJA": "$(execpath :ninja_built)/bin/ninja"},
    }),
    path = "$(execpath @rules_foreign_cc//toolchains/private:ninja_wrapper)",
    target = "@rules_foreign_cc//toolchains/private:ninja_wrapper",
    tools = [
        ":ninja_built",
    ],
)

toolchain(
    name = "ninja_toolchain",
    toolchain = ":ninja_tool",
    toolchain_type = "@rules_foreign_cc//toolchains:ninja_toolchain",
)
"""

_MESON_SRC_BUILD_FILE = """\
load("@rules_foreign_cc//foreign_cc/built_tools:meson_build.bzl", "meson_tool")
load("@rules_foreign_cc//toolchains/native_tools:native_tools_toolchain.bzl", "native_tool_toolchain")

package(default_visibility = ["//visibility:public"])

exports_files(["meson.py"])

filegroup(
    name = "all_srcs",
    srcs = glob(["**"]),
)

filegroup(
    name = "runtime",
    # NOTE: excluding __pycache__ is important to avoid rebuilding due to pyc
    # files, see https://github.com/bazel-contrib/rules_foreign_cc/issues/1342
    srcs = glob(["mesonbuild/**"], exclude = ["**/__pycache__/*"]),
)

meson_tool(
    name = "meson_built",
    data = [":runtime"],
    main = ":meson.py",
    tags = ["manual"],
)

native_tool_toolchain(
    name = "meson_tool",
    env = {
        "MESON": "$(execpath :meson_built)",
        "REAL_MESON": "$(rlocationpath :meson.py)",
    },
    path = "$(execpath :meson_built)",
    target = ":meson_built",
    tools = [":meson.py"],
)

toolchain(
    name = "meson_toolchain",
    toolchain = ":meson_tool",
    toolchain_type = "@rules_foreign_cc//toolchains:meson_toolchain",
)
"""

_PKGCONFIG_SRC_BUILD_FILE = """\
load("@rules_foreign_cc//foreign_cc/built_tools:pkgconfig_build.bzl", "pkgconfig_tool")
load("@rules_foreign_cc//toolchains/native_tools:native_tools_toolchain.bzl", "native_tool_toolchain")

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "all_srcs",
    srcs = glob(["**"]),
)

pkgconfig_tool(
    name = "pkgconfig_built",
    srcs = ":all_srcs",
    resource_size = "small",
    tags = ["manual"],
)

native_tool_toolchain(
    name = "pkgconfig_tool",
    env = select({
        "@platforms//os:windows": {"PKG_CONFIG": "$(execpath :pkgconfig_built)"},
        "//conditions:default": {"PKG_CONFIG": "$(execpath :pkgconfig_built)/bin/pkg-config"},
    }),
    path = select({
        "@platforms//os:windows": "$(execpath :pkgconfig_built)",
        "//conditions:default": "$(execpath :pkgconfig_built)/bin/pkg-config",
    }),
    target = ":pkgconfig_built",
)

toolchain(
    name = "pkgconfig_toolchain",
    toolchain = ":pkgconfig_tool",
    toolchain_type = "@rules_foreign_cc//toolchains:pkgconfig_toolchain",
)
"""

def _http_archive_kwargs(spec):
    """Pick whichever of sha256/integrity is non-empty, drop the rest."""
    kwargs = {
        "patches": list(spec.patches),
        "strip_prefix": spec.strip_prefix,
        "urls": list(spec.urls),
    }
    if spec.sha256:
        kwargs["sha256"] = spec.sha256
    if spec.integrity:
        kwargs["integrity"] = spec.integrity
    return kwargs

def _archive_for(srcs_dict, version, tool_name, name, build_file_content, extra_patches = []):
    spec = srcs_dict.get(version)
    if not spec:
        fail("Unsupported {} version: {}. Known versions: {}".format(
            tool_name,
            version,
            sorted(srcs_dict.keys()),
        ))
    kwargs = _http_archive_kwargs(spec)
    if extra_patches:
        kwargs["patches"] = list(kwargs["patches"]) + list(extra_patches)
    maybe(
        http_archive,
        name = name,
        build_file_content = build_file_content,
        **kwargs
    )

# buildifier: disable=unnamed-macro
# buildifier: disable=function-docstring-args
def cmake_source_spokes(version, register_toolchains = False):
    """Define the @cmake_src_<version> archive for a source-mode cmake."""
    name = source_spoke_repo("cmake", version)
    _archive_for(
        CMAKE_SRC_SRCS,
        version,
        "cmake",
        name,
        _CMAKE_SRC_BUILD_FILE,
        extra_patches = [Label("//toolchains/patches:cmake-c++11.patch")],
    )
    if register_toolchains:
        native.register_toolchains("@{}//:cmake_toolchain".format(name))

# buildifier: disable=unnamed-macro
# buildifier: disable=function-docstring-args
def make_source_spokes(version, register_toolchains = False):
    """Define the @make_src_<version> archive for a source-mode make."""
    name = source_spoke_repo("make", version)
    _archive_for(GNUMAKE_SRCS, version, "make", name, _MAKE_SRC_BUILD_FILE)
    if register_toolchains:
        native.register_toolchains("@{}//:make_toolchain".format(name))

# buildifier: disable=unnamed-macro
# buildifier: disable=function-docstring-args
def ninja_source_spokes(version, register_toolchains = False):
    """Define the @ninja_src_<version> archive for a source-mode ninja."""
    name = source_spoke_repo("ninja", version)
    _archive_for(NINJA_SRC_SRCS, version, "ninja", name, _NINJA_SRC_BUILD_FILE)
    if register_toolchains:
        native.register_toolchains("@{}//:ninja_toolchain".format(name))

# buildifier: disable=unnamed-macro
# buildifier: disable=function-docstring-args
def meson_source_spokes(version, register_toolchains = False):
    """Define the @meson_src_<version> archive for a source-mode meson."""
    name = source_spoke_repo("meson", version)
    _archive_for(MESON_SRCS, version, "meson", name, _MESON_SRC_BUILD_FILE)
    if register_toolchains:
        native.register_toolchains("@{}//:meson_toolchain".format(name))

# buildifier: disable=unnamed-macro
# buildifier: disable=function-docstring-args
def pkgconfig_source_spokes(version, register_toolchains = False):
    """Define the @pkgconfig_src_<version> archive plus glib/gettext companions."""

    # The four glib/gettext archives below are version-independent companions
    # of pkg-config on Windows. They live here because pkgconfig_source_spokes
    # is the source-mode entry point; they are not version-keyed.
    maybe(
        http_archive,
        name = "glib_dev",
        build_file_content = '''
cc_import(
    name = "glib_dev",
    hdrs = glob(["include/**"]),
    shared_library = "@glib_runtime//:bin/libglib-2.0-0.dll",
    visibility = ["//visibility:public"],
)
        ''',
        sha256 = "bdf18506df304d38be98a4b3f18055b8b8cca81beabecad0eece6ce95319c369",
        urls = [
            "https://mirror.bazel.build/download.gnome.org/binaries/win64/glib/2.26/glib-dev_2.26.1-1_win64.zip",
            "https://download.gnome.org/binaries/win64/glib/2.26/glib-dev_2.26.1-1_win64.zip",
        ],
    )

    maybe(
        http_archive,
        name = "glib_src",
        build_file_content = '''
cc_import(
    name = "msvc_hdr",
    hdrs = ["msvc_recommended_pragmas.h"],
    visibility = ["//visibility:public"],
)
        ''',
        sha256 = "bc96f63112823b7d6c9f06572d2ad626ddac7eb452c04d762592197f6e07898e",
        strip_prefix = "glib-2.26.1",
        urls = [
            "https://mirror.bazel.build/download.gnome.org/sources/glib/2.26/glib-2.26.1.tar.gz",
            "https://download.gnome.org/sources/glib/2.26/glib-2.26.1.tar.gz",
        ],
    )

    maybe(
        http_archive,
        name = "glib_runtime",
        build_file_content = '''
exports_files(
    [
        "bin/libgio-2.0-0.dll",
        "bin/libglib-2.0-0.dll",
        "bin/libgmodule-2.0-0.dll",
        "bin/libgobject-2.0-0.dll",
        "bin/libgthread-2.0-0.dll",
    ],
    visibility = ["//visibility:public"],
)
        ''',
        sha256 = "88d857087e86f16a9be651ee7021880b3f7ba050d34a1ed9f06113b8799cb973",
        urls = [
            "https://mirror.bazel.build/download.gnome.org/binaries/win64/glib/2.26/glib_2.26.1-1_win64.zip",
            "https://download.gnome.org/binaries/win64/glib/2.26/glib_2.26.1-1_win64.zip",
        ],
    )

    maybe(
        http_archive,
        name = "gettext_runtime",
        build_file_content = '''
cc_import(
    name = "gettext_runtime",
    shared_library = "bin/libintl-8.dll",
    visibility = ["//visibility:public"],
)
        ''',
        sha256 = "1f4269c0e021076d60a54e98da6f978a3195013f6de21674ba0edbc339c5b079",
        urls = [
            "https://mirror.bazel.build/download.gnome.org/binaries/win64/dependencies/gettext-runtime_0.18.1.1-2_win64.zip",
            "https://download.gnome.org/binaries/win64/dependencies/gettext-runtime_0.18.1.1-2_win64.zip",
        ],
    )

    name = source_spoke_repo("pkgconfig", version)
    _archive_for(PKGCONFIG_SRCS, version, "pkgconfig", name, _PKGCONFIG_SRC_BUILD_FILE)
    if register_toolchains:
        native.register_toolchains("@{}//:pkgconfig_toolchain".format(name))
