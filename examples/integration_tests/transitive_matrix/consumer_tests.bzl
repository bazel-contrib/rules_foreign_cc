"""Consumer app/runtime test macros for the transitive native/foreign matrix."""

load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

_ALL_SUPPORTED_PLATFORMS = select({
    "@platforms//os:linux": [],
    "@platforms//os:macos": [],
    "@platforms//os:windows": [],
    "//conditions:default": ["@platforms//:incompatible"],
})

_APP_LINKOPTS = select({
    "@platforms//os:linux": ["-ldl"],
    "//conditions:default": [],
})

_APP_SRC = "//integration_tests/transitive_matrix:app.c"
_CONSUMER_BINARY = select({
    "@platforms//os:windows": ["app.exe"],
    "//conditions:default": ["app"],
})
_FOREIGN_APP_SRCS = "//integration_tests/transitive_matrix:foreign_app_srcs"

def expected_loaded_libraries(libarchive = None, zlib = None):
    """Returns the runtime libraries a consumer test expects to load.

    Args:
      libarchive: Optional libarchive target label expected at runtime.
      zlib: Optional zlib target label expected at runtime.

    Returns:
      A dict keyed by logical library name with target labels as values.
    """
    expected = {}
    if libarchive:
        expected["libarchive"] = libarchive
    if zlib:
        expected["zlib"] = zlib
    return expected

def expected_linkage(
        app_shared_deps = [],
        app_static_deps = [],
        app_shared_deps_windows = None,
        app_static_deps_windows = None,
        libarchive = None,
        libarchive_shared_deps = [],
        libarchive_static_deps = []):
    """Returns linkage expectations for a consumer test.

    Args:
      app_shared_deps: Logical libraries expected as app dynamic deps.
      app_static_deps: Logical libraries not expected as app dynamic deps.
      app_shared_deps_windows: Optional Windows override for app_shared_deps.
      app_static_deps_windows: Optional Windows override for app_static_deps.
      libarchive: Optional libarchive target label to inspect for transitive
        dynamic deps.
      libarchive_shared_deps: Logical libraries expected as libarchive dynamic deps.
      libarchive_static_deps: Logical libraries not expected as libarchive dynamic deps.

    Returns:
      A struct containing linkage expectations for the app and libarchive.
    """
    return struct(
        app_shared_deps = app_shared_deps,
        app_shared_deps_windows = app_shared_deps_windows,
        app_static_deps = app_static_deps,
        app_static_deps_windows = app_static_deps_windows,
        libarchive = libarchive,
        libarchive_shared_deps = libarchive_shared_deps,
        libarchive_static_deps = libarchive_static_deps,
    )

def cmake_cache_entries(
        libarchive,
        libarchive_windows = None,
        zlib = None,
        zlib_windows = None):
    """Returns CMake cache entries for platform-specific dependency names.

    Args:
      libarchive: Default libarchive library name.
      libarchive_windows: Optional Windows libarchive import library name.
      zlib: Optional default zlib library name.
      zlib_windows: Optional Windows zlib import library name.

    Returns:
      A select() expression for the CMake cache entries.
    """
    default_entries = {
        "LIBARCHIVE_LIBRARY_NAME": libarchive,
    }
    windows_entries = {
        "LIBARCHIVE_LIBRARY_NAME": libarchive_windows or libarchive,
    }

    if zlib:
        default_entries["ZLIB_LIBRARY_NAME"] = zlib
        windows_entries["ZLIB_LIBRARY_NAME"] = zlib_windows or zlib

    return select({
        "@platforms//os:windows": windows_entries,
        "//conditions:default": default_entries,
    })

def _linkage_checks(binary, libarchive, expected_linkage, app_shared_deps, app_static_deps):
    checks = []

    for library in app_shared_deps:
        checks.append(("app", "dynamic", library, binary))
    for library in app_static_deps:
        checks.append(("app", "static", library, binary))

    if expected_linkage.libarchive_shared_deps or expected_linkage.libarchive_static_deps:
        if not libarchive:
            fail("libarchive linkage checks require expected_linkage.libarchive")

    for library in expected_linkage.libarchive_shared_deps:
        checks.append(("libarchive", "dynamic", library, libarchive))
    for library in expected_linkage.libarchive_static_deps:
        checks.append(("libarchive", "static", library, libarchive))

    return checks

def _linkage_manifest_cmd(checks):
    return "\n".join(
        ["rm -f \"$@\""] + [
            "printf 'check\\t%s\\t%s\\t%s\\t%s\\n' '{}' '{}' '{}' '$(rlocationpaths {})' >> \"$@\"".format(
                inspect_name,
                expected,
                library,
                inspect_label,
            )
            for inspect_name, expected, library, inspect_label in checks
        ],
    )

def _or_default(value, default):
    return default if value == None else value

def runtime_test(
        name,
        binary,
        binary_name,
        target_compatible_with,
        expected_loaded_libraries = {},
        tags = []):
    manifest_name = name + "_manifest"

    # Example output:
    #   binary_name  app
    #   binary       integration_tests/.../case/app
    #   expect       libarchive  external/.../examples_libarchive/.../libarchive.so
    #   expect       zlib        external/.../examples_zlib/.../libz.so
    native.genrule(
        name = manifest_name,
        srcs = [binary] + expected_loaded_libraries.values(),
        outs = [name + ".runtime_manifest"],
        cmd = "\n".join(
            [
                "printf 'binary_name\\t%s\\n' '{}' > \"$@\"".format(binary_name),
                "printf 'binary\\t%s\\n' '$(rlocationpaths {})' >> \"$@\"".format(binary),
            ] + [
                "printf 'expect\\t%s\\t%s\\n' '{}' '$(rlocationpaths {})' >> \"$@\"".format(
                    library_name,
                    library,
                )
                for library_name, library in expected_loaded_libraries.items()
            ],
        ),
        target_compatible_with = target_compatible_with,
    )

    sh_test(
        name = name,
        size = "small",
        srcs = ["//integration_tests/transitive_matrix:runtime_test.sh"],
        args = [
            "$(rlocationpath :{})".format(manifest_name),
        ],
        data = [
            ":" + manifest_name,
            binary,
            "@coreutils_toolchains//:resolved_toolchain",
            "@bazel_tools//tools/bash/runfiles",
        ] + expected_loaded_libraries.values(),
        env = {
            "COREUTILS_RLOCATION_PATH": "$(rlocationpath @coreutils_toolchains//:resolved_toolchain)",
        },
        tags = tags,
        target_compatible_with = target_compatible_with,
    )

def linkage_test(
        name,
        binary,
        expected_loaded_libraries,
        expected_linkage,
        target_compatible_with,
        tags = []):
    """Creates a shell test that validates expected binary linkage.

    Args:
      name: Name of the generated sh_test target.
      binary: Label of the binary to inspect.
      expected_loaded_libraries: Libraries that are expected to be loaded by the binary. Should be returned by expected_loaded_libraries().
      expected_linkage: Linkage expectations returned by expected_linkage().
      target_compatible_with: Platform compatibility for generated targets.
      tags: Additional tags to apply to the generated sh_test target.
    """
    manifest_name = name + "_manifest"
    libarchive = expected_linkage.libarchive or expected_loaded_libraries.get("libarchive")
    default_checks = _linkage_checks(
        binary,
        libarchive,
        expected_linkage,
        expected_linkage.app_shared_deps,
        expected_linkage.app_static_deps,
    )
    windows_checks = _linkage_checks(
        binary,
        libarchive,
        expected_linkage,
        _or_default(expected_linkage.app_shared_deps_windows, expected_linkage.app_shared_deps),
        _or_default(expected_linkage.app_static_deps_windows, expected_linkage.app_static_deps),
    )
    manifest_cmd = _linkage_manifest_cmd(default_checks)
    if (
        expected_linkage.app_shared_deps_windows != None or
        expected_linkage.app_static_deps_windows != None
    ):
        manifest_cmd = select({
            "@platforms//os:windows": _linkage_manifest_cmd(windows_checks),
            "//conditions:default": manifest_cmd,
        })

    # Linkage manifest rows are tab-separated:
    #
    #   check  <inspect-name>  <static|dynamic>  <library>  <rlocationpaths>
    #
    # Examples:
    #
    #   check  app         dynamic  libarchive  <paths to app>
    #   check  libarchive  dynamic  zlib        <paths to libarchive>
    #   check  app         static   zlib        <paths to app>
    #
    # `dynamic` means the inspected file must have a loader-visible dependency
    # on the library. `static` means it must not. The paired runtime test proves
    # the program still works.
    native.genrule(
        name = manifest_name,
        srcs = [binary] + ([libarchive] if libarchive else []),
        outs = [name + ".linkage_manifest"],
        cmd = manifest_cmd,
        target_compatible_with = target_compatible_with,
    )

    sh_test(
        name = name,
        size = "small",
        srcs = ["//integration_tests/transitive_matrix:linkage_test.sh"],
        args = [
            "$(rlocationpath :{})".format(manifest_name),
        ],
        data = [
            ":" + manifest_name,
            binary,
            "@bazel_tools//tools/bash/runfiles",
        ] + ([libarchive] if libarchive else []),
        tags = tags,
        target_compatible_with = target_compatible_with,
    )

def cc_binary_consumer_test(
        name,
        deps,
        expected_loaded_libraries,
        expected_linkage,
        dynamic_deps = [],
        linkstatic = False,
        linkopts = _APP_LINKOPTS,
        target_compatible_with = _ALL_SUPPORTED_PLATFORMS,
        tags = []):
    cc_binary(
        name = name,
        srcs = [_APP_SRC],
        dynamic_deps = dynamic_deps,
        linkopts = linkopts,
        linkstatic = linkstatic,
        target_compatible_with = target_compatible_with,
        deps = deps,
    )

    runtime_test(
        name = name + "_test",
        binary = ":" + name,
        binary_name = name,
        expected_loaded_libraries = expected_loaded_libraries,
        tags = tags,
        target_compatible_with = target_compatible_with,
    )

    linkage_test(
        name = name + "_linkage_test",
        binary = ":" + name,
        expected_loaded_libraries = expected_loaded_libraries,
        expected_linkage = expected_linkage,
        tags = tags,
        target_compatible_with = target_compatible_with,
    )

def cmake_consumer_test(
        name,
        deps,
        cache_entries,
        expected_loaded_libraries,
        expected_linkage,
        dynamic_deps = [],
        target_compatible_with = _ALL_SUPPORTED_PLATFORMS,
        tags = []):
    cmake(
        name = name,
        cache_entries = cache_entries,
        dynamic_deps = dynamic_deps,
        lib_source = _FOREIGN_APP_SRCS,
        out_binaries = _CONSUMER_BINARY,
        out_include_dir = "",
        runtime_library_search_directories = "enabled",
        target_compatible_with = target_compatible_with,
        deps = deps,
    )

    runtime_test(
        name = name + "_test",
        binary = ":" + name,
        binary_name = "app",
        expected_loaded_libraries = expected_loaded_libraries,
        tags = tags,
        target_compatible_with = target_compatible_with,
    )

    linkage_test(
        name = name + "_linkage_test",
        binary = ":" + name,
        expected_loaded_libraries = expected_loaded_libraries,
        expected_linkage = expected_linkage,
        tags = tags,
        target_compatible_with = target_compatible_with,
    )
