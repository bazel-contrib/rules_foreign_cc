"""
Defines repositories and register toolchains for versions of the tools built
from source
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@rules_foreign_cc//toolchains:cmake_versions.bzl", _CMAKE_SRCS = "CMAKE_SRCS")

_ALL_CONTENT = """\
filegroup(
    name = "all_srcs",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)
"""

_MESON_BUILD_FILE_CONTENT = """\
exports_files(["meson.py"])

filegroup(
    name = "runtime",
    # NOTE: excluding __pycache__ is important to avoid rebuilding due to pyc
    # files, see https://github.com/bazel-contrib/rules_foreign_cc/issues/1342
    srcs = glob(["mesonbuild/**"], exclude = ["**/__pycache__/*"]),
    visibility = ["//visibility:public"],
)
"""

# buildifier: disable=unnamed-macro
def built_toolchains(cmake_version, make_version, ninja_version, meson_version, pkgconfig_version, register_toolchains, register_built_pkgconfig_toolchain):
    """
    Registers toolchains for built tools that will be built from source.

    Args:
        cmake_version (str): The CMake version to build.
        make_version (str): The Make version to build.
        ninja_version (str): The Ninja version to build.
        meson_version (str): The Meson version to build.
        pkgconfig_version (str): The pkg-config version to build.
        register_toolchains (bool): Whether to register the toolchains via native.register_toolchains. Used by bzlmod.
        register_built_pkgconfig_toolchain (bool): Whether the built pkgconfig toolchain will be registered.
    """
    cmake_toolchain(
        version = cmake_version,
        register_toolchains = register_toolchains,
    )
    make_toolchain(
        version = make_version,
        register_toolchains = register_toolchains,
    )
    ninja_toolchain(
        version = ninja_version,
        register_toolchains = register_toolchains,
    )
    meson_toolchain(
        version = meson_version,
        register_toolchains = register_toolchains,
    )

    if register_built_pkgconfig_toolchain:
        pkgconfig_toolchain(
            version = pkgconfig_version,
            register_toolchains = register_toolchains,
        )

_CMAKE_TOOLCHAIN_TEMPLATE = """\
load("@rules_foreign_cc//foreign_cc/built_tools:cmake_build.bzl", "cmake_tool")
load("@rules_foreign_cc//toolchains/native_tools:native_tools_toolchain.bzl", "native_tool_toolchain")

cmake_tool(
    name = "cmake_tool",
    srcs = "@{name}//:all_srcs",
    tags = ["manual"],
)

native_tool_toolchain(
    name = "built_cmake",
    env = select({{
        "@platforms//os:windows": {{"CMAKE": "$(execpath :cmake_tool)/bin/cmake.exe"}},
        "//conditions:default": {{"CMAKE": "$(execpath :cmake_tool)/bin/cmake"}},
    }}),
    path = select({{
        "@platforms//os:windows": "$(execpath :cmake_tool)/bin/cmake.exe",
        "//conditions:default": "$(execpath :cmake_tool)/bin/cmake",
    }}),
    target = ":cmake_tool",
)

toolchain(
    name = "built_cmake_toolchain",
    toolchain = ":built_cmake",
    toolchain_type = "@rules_foreign_cc//toolchains:cmake_toolchain",
)
"""

def cmake_toolchain(
        *,
        version,
        register_toolchains,
        name = "cmake_src"):
    """
    Registers a toolchain for CMake built from source.

    Args:
        version (str): The version of CMake to use.
        register_toolchains (bool): Whether to register the toolchains.
        name (str, optional): The name of the toolchain.

    Returns:
        list: Toolchain definitions.
    """
    if register_toolchains:
        native.register_toolchains(
            "@rules_foreign_cc//toolchains:built_cmake_toolchain",
        )

    if _CMAKE_SRCS.get(version):
        cmake_meta = _CMAKE_SRCS[version]
        urls = cmake_meta[0]
        prefix = cmake_meta[1]
        sha256 = cmake_meta[2]
        maybe(
            http_archive,
            name = name,
            build_file_content = _ALL_CONTENT,
            sha256 = sha256,
            strip_prefix = prefix,
            urls = urls,
            patches = [
                Label("//toolchains/patches:cmake-c++11.patch"),
            ],
        )
        return [_CMAKE_TOOLCHAIN_TEMPLATE.format(
            name = name,
        )]

    fail("Unsupported cmake version: " + str(version))

_MAKE_TOOLCHAIN_TEMPLATE = """\
load("@rules_foreign_cc//foreign_cc/built_tools:make_build.bzl", "make_tool")
load("@rules_foreign_cc//toolchains/native_tools:native_tools_toolchain.bzl", "native_tool_toolchain")

make_tool(
    name = "make_tool",
    srcs = "@{name}//:all_srcs",
    tags = ["manual"],
)

native_tool_toolchain(
    name = "built_make",
    env = select({{
        "@platforms//os:windows": {{"MAKE": "$(execpath :make_tool)/bin/make.exe"}},
        "//conditions:default": {{"MAKE": "$(execpath :make_tool)/bin/make"}},
    }}),
    path = select({{
        "@platforms//os:windows": "$(execpath :make_tool)/bin/make.exe",
        "//conditions:default": "$(execpath :make_tool)/bin/make",
    }}),
    target = ":make_tool",
)

toolchain(
    name = "built_make_toolchain",
    toolchain = ":built_make",
    toolchain_type = "@rules_foreign_cc//toolchains:make_toolchain",
)
"""

def make_toolchain(
        *,
        version,
        register_toolchains,
        name = "gnumake_src"):
    """
    Registers a toolchain for GNU Make built from source.

    Args:
        version (str): The version of GNU Make to use.
        register_toolchains (bool): Whether to register the toolchains.
        name (str, optional): The name of the toolchain.

    Returns:
        list: Toolchain definitions.
    """
    if register_toolchains:
        native.register_toolchains(
            "@rules_foreign_cc//toolchains:built_make_toolchain",
        )

    if version == "4.4.1":
        maybe(
            http_archive,
            name = name,
            build_file_content = _ALL_CONTENT,
            sha256 = "dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3",
            strip_prefix = "make-4.4.1",
            urls = [
                "https://mirror.bazel.build/ftpmirror.gnu.org/gnu/make/make-4.4.1.tar.gz",
                "http://ftpmirror.gnu.org/gnu/make/make-4.4.1.tar.gz",
            ],
        )
        return [_MAKE_TOOLCHAIN_TEMPLATE.format(name = name)]

    if version == "4.4":
        maybe(
            http_archive,
            name = name,
            build_file_content = _ALL_CONTENT,
            sha256 = "581f4d4e872da74b3941c874215898a7d35802f03732bdccee1d4a7979105d18",
            strip_prefix = "make-4.4",
            urls = [
                "https://mirror.bazel.build/ftpmirror.gnu.org/gnu/make/make-4.4.tar.gz",
                "http://ftpmirror.gnu.org/gnu/make/make-4.4.tar.gz",
            ],
        )
        return [_MAKE_TOOLCHAIN_TEMPLATE.format(name = name)]

    if version == "4.3":
        maybe(
            http_archive,
            name = name,
            build_file_content = _ALL_CONTENT,
            patches = [Label("//toolchains/patches:make-reproducible-bootstrap.patch")],
            sha256 = "e05fdde47c5f7ca45cb697e973894ff4f5d79e13b750ed57d7b66d8defc78e19",
            strip_prefix = "make-4.3",
            urls = [
                "https://mirror.bazel.build/ftpmirror.gnu.org/gnu/make/make-4.3.tar.gz",
                "http://ftpmirror.gnu.org/gnu/make/make-4.3.tar.gz",
            ],
        )
        return [_MAKE_TOOLCHAIN_TEMPLATE.format(name = name)]

    fail("Unsupported make version: " + str(version))

_NINJA_TOOLCHAIN_TEMPLATE = """\
load("//foreign_cc/built_tools:ninja_build.bzl", "ninja_tool")
load("//toolchains/native_tools:native_tools_toolchain.bzl", "native_tool_toolchain")

ninja_tool(
    name = "ninja_tool",
    srcs = "@{name}//:all_srcs",
    tags = ["manual"],
)

native_tool_toolchain(
    name = "built_ninja",
    env = select({{
        "@platforms//os:windows": {{"NINJA": "$(execpath :ninja_tool)/bin/ninja.exe"}},
        "//conditions:default": {{"NINJA": "$(execpath :ninja_tool)/bin/ninja"}},
    }}),
    path = select({{
        "@platforms//os:windows": "$(execpath :ninja_tool)/bin/ninja.exe",
        "//conditions:default": "$(execpath :ninja_tool)/bin/ninja",
    }}),
    target = ":ninja_tool",
)

toolchain(
    name = "built_ninja_toolchain",
    toolchain = ":built_ninja",
    toolchain_type = "@rules_foreign_cc//toolchains:ninja_toolchain",
)
"""

def ninja_toolchain(
        *,
        version,
        register_toolchains,
        name = "ninja_build_src"):
    """
    Registers a toolchain for Ninja built from source.

    Args:
        version (str): The version of Ninja to use.
        register_toolchains (bool): Whether to register the toolchains.
        name (str, optional): The name of the toolchain.

    Returns:
        list: Toolchain definitions.
    """
    if register_toolchains:
        native.register_toolchains(
            "@rules_foreign_cc//toolchains:built_ninja_toolchain",
        )
    if version == "1.12.1":
        maybe(
            http_archive,
            name = name,
            build_file_content = _ALL_CONTENT,
            integrity = "sha256-ghvf9Io/aDvEuztvC1/nstZHz2XVKutjMoyRpsbfKFo=",
            strip_prefix = "ninja-1.12.1",
            urls = [
                "https://mirror.bazel.build/github.com/ninja-build/ninja/archive/v1.12.1.tar.gz",
                "https://github.com/ninja-build/ninja/archive/v1.12.1.tar.gz",
            ],
        )
        return [_NINJA_TOOLCHAIN_TEMPLATE.format(name = name)]
    if version == "1.12.0":
        maybe(
            http_archive,
            name = name,
            build_file_content = _ALL_CONTENT,
            integrity = "sha256-iyyGzUg9x/y3l1xexzKRNdIQCZqJvH2wWQoHsLv+SaU=",
            strip_prefix = "ninja-1.12.0",
            urls = [
                "https://mirror.bazel.build/github.com/ninja-build/ninja/archive/v1.12.0.tar.gz",
                "https://github.com/ninja-build/ninja/archive/v1.12.0.tar.gz",
            ],
        )
        return [_NINJA_TOOLCHAIN_TEMPLATE.format(name = name)]
    if version == "1.11.1":
        maybe(
            http_archive,
            name = name,
            build_file_content = _ALL_CONTENT,
            sha256 = "31747ae633213f1eda3842686f83c2aa1412e0f5691d1c14dbbcc67fe7400cea",
            strip_prefix = "ninja-1.11.1",
            urls = [
                "https://mirror.bazel.build/github.com/ninja-build/ninja/archive/v1.11.1.tar.gz",
                "https://github.com/ninja-build/ninja/archive/v1.11.1.tar.gz",
            ],
        )
        return [_NINJA_TOOLCHAIN_TEMPLATE.format(name = name)]
    if version == "1.11.0":
        maybe(
            http_archive,
            name = name,
            build_file_content = _ALL_CONTENT,
            sha256 = "3c6ba2e66400fe3f1ae83deb4b235faf3137ec20bd5b08c29bfc368db143e4c6",
            strip_prefix = "ninja-1.11.0",
            urls = [
                "https://mirror.bazel.build/github.com/ninja-build/ninja/archive/v1.11.0.tar.gz",
                "https://github.com/ninja-build/ninja/archive/v1.11.0.tar.gz",
            ],
        )
        return [_NINJA_TOOLCHAIN_TEMPLATE.format(name = name)]
    if version == "1.10.2":
        maybe(
            http_archive,
            name = name,
            build_file_content = _ALL_CONTENT,
            sha256 = "ce35865411f0490368a8fc383f29071de6690cbadc27704734978221f25e2bed",
            strip_prefix = "ninja-1.10.2",
            urls = [
                "https://mirror.bazel.build/github.com/ninja-build/ninja/archive/v1.10.2.tar.gz",
                "https://github.com/ninja-build/ninja/archive/v1.10.2.tar.gz",
            ],
        )
        return [_NINJA_TOOLCHAIN_TEMPLATE.format(name = name)]

    fail("Unsupported ninja version: " + str(version))

_MESON_TOOLCHAIN_TEMPLATE = """\
load("@rules_foreign_cc//foreign_cc/built_tools:meson_build.bzl", "meson_tool")
load("@rules_foreign_cc//toolchains/native_tools:native_tools_toolchain.bzl", "native_tool_toolchain")

alias(
    name = "meson_runtime",
    actual = "@{name}//:runtime",
)

alias(
    name = "meson.py",
    actual = "@{name}//:meson.py",
)

meson_tool(
    name = "meson_tool",
    data = [":meson_runtime"],
    main = "//:meson.py",
    tags = ["manual"],
)

native_tool_toolchain(
    name = "built_meson",
    env = {{"MESON": "$(execpath :meson_tool)"}},
    path = "$(execpath :meson_tool)",
    target = ":meson_tool",
)

toolchain(
    name = "built_meson_toolchain",
    toolchain = ":built_meson",
    toolchain_type = "@rules_foreign_cc//toolchains:meson_toolchain",
)
"""

def meson_toolchain(
        *,
        version,
        register_toolchains,
        name = "meson_src"):
    """
    Registers a toolchain for Meson built from source.

    Args:
        version (str): The version of Meson to use.
        register_toolchains (bool): Whether to register the toolchains.
        name (str, optional): The name of the toolchain.

    Returns:
        list: Toolchain definitions.
    """
    if register_toolchains:
        native.register_toolchains(
            "@rules_foreign_cc//toolchains:built_meson_toolchain",
        )
    if version == "1.5.1":
        maybe(
            http_archive,
            name = name,
            build_file_content = _MESON_BUILD_FILE_CONTENT,
            sha256 = "567e533adf255de73a2de35049b99923caf872a455af9ce03e01077e0d384bed",
            strip_prefix = "meson-1.5.1",
            urls = [
                "https://mirror.bazel.build/github.com/mesonbuild/meson/releases/download/1.5.1/meson-1.5.1.tar.gz",
                "https://github.com/mesonbuild/meson/releases/download/1.5.1/meson-1.5.1.tar.gz",
            ],
        )
        return [_MESON_TOOLCHAIN_TEMPLATE.format(name = name)]
    if version == "1.1.1":
        maybe(
            http_archive,
            name = name,
            build_file_content = _MESON_BUILD_FILE_CONTENT,
            sha256 = "d04b541f97ca439fb82fab7d0d480988be4bd4e62563a5ca35fadb5400727b1c",
            strip_prefix = "meson-1.1.1",
            urls = [
                "https://mirror.bazel.build/github.com/mesonbuild/meson/releases/download/1.1.1/meson-1.1.1.tar.gz",
                "https://github.com/mesonbuild/meson/releases/download/1.1.1/meson-1.1.1.tar.gz",
            ],
        )
        return [_MESON_TOOLCHAIN_TEMPLATE.format(name = name)]
    if version == "0.63.0":
        maybe(
            http_archive,
            name = name,
            build_file_content = _MESON_BUILD_FILE_CONTENT,
            sha256 = "3b51d451744c2bc71838524ec8d96cd4f8c4793d5b8d5d0d0a9c8a4f7c94cd6f",
            strip_prefix = "meson-0.63.0",
            urls = [
                "https://mirror.bazel.build/github.com/mesonbuild/meson/releases/download/0.63.0/meson-0.63.0.tar.gz",
                "https://github.com/mesonbuild/meson/releases/download/0.63.0/meson-0.63.0.tar.gz",
            ],
        )
        return [_MESON_TOOLCHAIN_TEMPLATE.format(name = name)]

    fail("Unsupported meson version: " + str(version))

_PKGCONFIG_TOOLCHAIN_TEMPLATE = """\
load("@rules_foreign_cc//foreign_cc/built_tools:pkgconfig_build.bzl", "pkgconfig_tool")
load("@rules_foreign_cc//toolchains/native_tools:native_tools_toolchain.bzl", "native_tool_toolchain")

pkgconfig_tool(
    name = "pkgconfig_tool",
    srcs = "@{name}//:all_srcs",
    tags = ["manual"],
)

native_tool_toolchain(
    name = "built_pkgconfig",
    env = select({{
        "@platforms//os:windows": {{"PKG_CONFIG": "$(execpath :pkgconfig_tool)"}},
        "//conditions:default": {{"PKG_CONFIG": "$(execpath :pkgconfig_tool)/bin/pkg-config"}},
    }}),
    path = select({{
        "@platforms//os:windows": "$(execpath :pkgconfig_tool)",
        "//conditions:default": "$(execpath :pkgconfig_tool)/bin/pkg-config",
    }}),
    target = ":pkgconfig_tool",
)

toolchain(
    name = "built_pkgconfig_toolchain",
    toolchain = ":built_pkgconfig",
    toolchain_type = "@rules_foreign_cc//toolchains:pkgconfig_toolchain",
)
"""

def pkgconfig_toolchain(
        *,
        version,
        register_toolchains,
        name = "pkgconfig_src",
        glib_dev_name = "glib_dev",
        glib_src_name = "glib_src",
        glib_runtime_name = "glib_runtime",
        gettext_runtime_name = "gettext_runtime"):
    """Registers a toolchain for pkgconfig built from source.

    Args:
        version (str): The version of Ninja to use.
        register_toolchains (bool): Whether to register the toolchains.
        name (str, optional): The name of the toolchain.
        glib_dev_name (str, optional): The name of the toolchain.
        glib_src_name (str, optional):  The name of the toolchain.
        glib_runtime_name (str, optional):  The name of the toolchain.
        gettext_runtime_name (str, optional):  The name of the toolchain.

    Returns:
        list: Toolchain definitions.
    """
    if register_toolchains:
        native.register_toolchains(
            "@rules_foreign_cc//toolchains:built_pkgconfig_toolchain",
        )

    maybe(
        http_archive,
        name = glib_dev_name,
        build_file_content = """
cc_import(
    name = "glib_dev",
    hdrs = glob(["include/**"]),
    shared_library = "@glib_runtime//:bin/libglib-2.0-0.dll",
    visibility = ["//visibility:public"],
)
        """,
        sha256 = "bdf18506df304d38be98a4b3f18055b8b8cca81beabecad0eece6ce95319c369",
        urls = [
            "https://mirror.bazel.build/download.gnome.org/binaries/win64/glib/2.26/glib-dev_2.26.1-1_win64.zip",
            "https://download.gnome.org/binaries/win64/glib/2.26/glib-dev_2.26.1-1_win64.zip",
        ],
    )

    maybe(
        http_archive,
        name = glib_src_name,
        build_file_content = """
cc_import(
    name = "msvc_hdr",
    hdrs = ["msvc_recommended_pragmas.h"],
    visibility = ["//visibility:public"],
)
        """,
        sha256 = "bc96f63112823b7d6c9f06572d2ad626ddac7eb452c04d762592197f6e07898e",
        strip_prefix = "glib-2.26.1",
        urls = [
            "https://mirror.bazel.build/download.gnome.org/sources/glib/2.26/glib-2.26.1.tar.gz",
            "https://download.gnome.org/sources/glib/2.26/glib-2.26.1.tar.gz",
        ],
    )

    maybe(
        http_archive,
        name = glib_runtime_name,
        build_file_content = """
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
        """,
        sha256 = "88d857087e86f16a9be651ee7021880b3f7ba050d34a1ed9f06113b8799cb973",
        urls = [
            "https://mirror.bazel.build/download.gnome.org/binaries/win64/glib/2.26/glib_2.26.1-1_win64.zip",
            "https://download.gnome.org/binaries/win64/glib/2.26/glib_2.26.1-1_win64.zip",
        ],
    )

    maybe(
        http_archive,
        name = gettext_runtime_name,
        build_file_content = """
cc_import(
    name = "gettext_runtime",
    shared_library = "bin/libintl-8.dll",
    visibility = ["//visibility:public"],
)
        """,
        sha256 = "1f4269c0e021076d60a54e98da6f978a3195013f6de21674ba0edbc339c5b079",
        urls = [
            "https://mirror.bazel.build/download.gnome.org/binaries/win64/dependencies/gettext-runtime_0.18.1.1-2_win64.zip",
            "https://download.gnome.org/binaries/win64/dependencies/gettext-runtime_0.18.1.1-2_win64.zip",
        ],
    )
    if version == "0.29.2":
        maybe(
            http_archive,
            name = name,
            build_file_content = _ALL_CONTENT,
            sha256 = "6fc69c01688c9458a57eb9a1664c9aba372ccda420a02bf4429fe610e7e7d591",
            strip_prefix = "pkg-config-0.29.2",
            # The patch is required as bazel does not provide the VCINSTALLDIR or WINDOWSSDKDIR vars
            patches = [
                # This patch is required as bazel does not provide the VCINSTALLDIR or WINDOWSSDKDIR vars
                Label("//toolchains/patches:pkgconfig-detectenv.patch"),

                # This patch is required as rules_foreign_cc runs in MSYS2 on Windows and MSYS2's "mkdir" is used
                Label("//toolchains/patches:pkgconfig-makefile-vc.patch"),

                # This patch fixes explicit integer conversion which causes errors in clang >= 15 and gcc >= 14
                Label("//toolchains/patches:pkgconfig-builtin-glib-int-conversion.patch"),
            ],
            urls = [
                "https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz",
                "https://mirror.bazel.build/pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz",
            ],
        )
        return [_PKGCONFIG_TOOLCHAIN_TEMPLATE.format(name = name)]

    fail("Unsupported pkgconfig version: " + str(version))
