# Usage Examples

This page provides practical examples of using rules_foreign_cc with Bzlmod.

## Basic CMake Project

This example shows how to build a simple CMake-based C++ library.

### MODULE.bazel

```starlark
bazel_dep(name = "rules_foreign_cc", version = "0.13.0")

tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
use_repo(
    tools,
    "prebuilt_cmake_toolchains",
    "prebuilt_ninja_toolchains",
    "rules_foreign_cc_framework_toolchains",
    "toolchain_hub",
)

register_toolchains(
    "@prebuilt_cmake_toolchains//:all",
    "@prebuilt_ninja_toolchains//:all",
    "@rules_foreign_cc_framework_toolchains//:all",
    "@toolchain_hub//:all",
)
```

### BUILD.bazel

```starlark
load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")

cmake(
    name = "mylib",
    lib_source = "@mylib_src//:all",
    out_static_libs = ["libmylib.a"],
    visibility = ["//visibility:public"],
)
```

## Using a Specific CMake Version

If your project requires a specific version of CMake:

### MODULE.bazel

```starlark
bazel_dep(name = "rules_foreign_cc", version = "0.13.0")

tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.cmake(version = "3.30.5")
use_repo(
    tools,
    "prebuilt_cmake_toolchains",
    "prebuilt_ninja_toolchains",
    "rules_foreign_cc_framework_toolchains",
    "toolchain_hub",
)

register_toolchains(
    "@prebuilt_cmake_toolchains//:all",
    "@prebuilt_ninja_toolchains//:all",
    "@rules_foreign_cc_framework_toolchains//:all",
    "@toolchain_hub//:all",
)
```

## Multiple Tool Versions

Configure multiple build tools for different projects:

### MODULE.bazel

```starlark
bazel_dep(name = "rules_foreign_cc", version = "0.13.0")

tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.cmake(version = "3.30.5")
tools.ninja(version = "1.12.0")
tools.make(version = "4.4.1")
tools.meson(version = "1.5.1")
use_repo(
    tools,
    "prebuilt_cmake_toolchains",
    "prebuilt_ninja_toolchains",
    "rules_foreign_cc_framework_toolchains",
    "toolchain_hub",
)

register_toolchains(
    "@prebuilt_cmake_toolchains//:all",
    "@prebuilt_ninja_toolchains//:all",
    "@rules_foreign_cc_framework_toolchains//:all",
    "@toolchain_hub//:all",
)
```

### BUILD.bazel

```starlark
load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake", "configure_make", "meson")

# CMake-based project
cmake(
    name = "cmake_lib",
    lib_source = "@cmake_lib_src//:all",
    out_static_libs = ["libcmake.a"],
)

# Autotools-based project
configure_make(
    name = "autotools_lib",
    lib_source = "@autotools_lib_src//:all",
    out_static_libs = ["libautotools.a"],
)

# Meson-based project
meson(
    name = "meson_lib",
    lib_source = "@meson_lib_src//:all",
    out_static_libs = ["libmeson.a"],
)
```

## Building OpenSSL

A real-world example of building OpenSSL from source with rules_foreign_cc:

### MODULE.bazel

```starlark
bazel_dep(name = "rules_foreign_cc", version = "0.13.0")

tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
use_repo(
    tools,
    "prebuilt_cmake_toolchains",
    "prebuilt_ninja_toolchains",
    "rules_foreign_cc_framework_toolchains",
    "toolchain_hub",
)

register_toolchains(
    "@prebuilt_cmake_toolchains//:all",
    "@prebuilt_ninja_toolchains//:all",
    "@rules_foreign_cc_framework_toolchains//:all",
    "@toolchain_hub//:all",
)

# Download OpenSSL source tarball
http_archive = use_repo_rule("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "openssl",
    build_file = "@//third_party:openssl.BUILD",
    sha256 = "f89199be8b23ca45fc7cb9f1d8d3ee67312318286ad030f5316aca6462db6c96",
    strip_prefix = "openssl-3.1.4",
    urls = [
        "https://www.openssl.org/source/openssl-3.1.4.tar.gz",
        "https://github.com/openssl/openssl/releases/download/openssl-3.1.4/openssl-3.1.4.tar.gz",
    ],
)
```

### third_party/openssl.BUILD

```starlark
load("@rules_foreign_cc//foreign_cc:defs.bzl", "configure_make")

filegroup(
    name = "all",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)

configure_make(
    name = "openssl",
    configure_command = "Configure",
    configure_in_place = True,
    configure_options = [
        "no-shared",
        "no-tests",
    ] + select({
        "@platforms//os:macos": select({
            "@platforms//cpu:aarch64": ["darwin64-arm64-cc"],
            "@platforms//cpu:x86_64": ["darwin64-x86_64-cc"],
            "//conditions:default": ["darwin64-x86_64-cc"],
        }),
        "@platforms//os:linux": select({
            "@platforms//cpu:aarch64": ["linux-aarch64"],
            "@platforms//cpu:x86_64": ["linux-x86_64"],
            "//conditions:default": ["linux-x86_64"],
        }),
        "//conditions:default": [],
    }),
    env = select({
        "@platforms//os:macos": {
            "AR": "",
        },
        "//conditions:default": {},
    }),
    lib_source = ":all",
    out_static_libs = [
        "libssl.a",
        "libcrypto.a",
    ],
    targets = [],
    visibility = ["//visibility:public"],
)
```

## Building with pkg-config

Using pkg-config to find dependencies:

### MODULE.bazel

```starlark
bazel_dep(name = "rules_foreign_cc", version = "0.13.0")

tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.cmake(version = "3.31.8")
tools.pkgconfig(version = "0.29.2")
use_repo(
    tools,
    "prebuilt_cmake_toolchains",
    "prebuilt_ninja_toolchains",
    "rules_foreign_cc_framework_toolchains",
    "toolchain_hub",
)

register_toolchains(
    "@prebuilt_cmake_toolchains//:all",
    "@prebuilt_ninja_toolchains//:all",
    "@rules_foreign_cc_framework_toolchains//:all",
    "@toolchain_hub//:all",
)
```

### BUILD.bazel

```starlark
load("@rules_foreign_cc//foreign_cc:defs.bzl", "configure_make")

configure_make(
    name = "glib",
    configure_options = [
        "--disable-shared",
        "--disable-libmount",
    ],
    lib_source = "@glib//:all",
    out_static_libs = [
        "libglib-2.0.a",
        "libgobject-2.0.a",
    ],
    # Dependencies that provide pkg-config files
    deps = [
        "@pcre//:pcre",
    ],
)
```

## Cross-Compilation

Building for a different target platform:

### MODULE.bazel

```starlark
bazel_dep(name = "rules_foreign_cc", version = "0.13.0")

tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.cmake(version = "3.31.8")
use_repo(
    tools,
    "prebuilt_cmake_toolchains",
    "prebuilt_ninja_toolchains",
    "rules_foreign_cc_framework_toolchains",
    "toolchain_hub",
)

register_toolchains(
    "@prebuilt_cmake_toolchains//:all",
    "@prebuilt_ninja_toolchains//:all",
    "@rules_foreign_cc_framework_toolchains//:all",
    "@toolchain_hub//:all",
)
```

### Build Command

```bash
# Build for Linux ARM64 from macOS
bazel build --platforms=@platforms//os:linux --platforms=@platforms//cpu:aarch64 //:mylib
```

## Using with External Dependencies

Combining rules_foreign_cc with other dependency management:

### MODULE.bazel

```starlark
bazel_dep(name = "rules_foreign_cc", version = "0.13.0")

# Configure tools
tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.cmake(version = "3.31.8")
use_repo(
    tools,
    "prebuilt_cmake_toolchains",
    "prebuilt_ninja_toolchains",
    "rules_foreign_cc_framework_toolchains",
    "toolchain_hub",
)

register_toolchains(
    "@prebuilt_cmake_toolchains//:all",
    "@prebuilt_ninja_toolchains//:all",
    "@rules_foreign_cc_framework_toolchains//:all",
    "@toolchain_hub//:all",
)

# Define external dependencies
http_archive = use_repo_rule("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "zlib",
    build_file = "@//third_party:zlib.BUILD",
    sha256 = "...",
    strip_prefix = "zlib-1.2.13",
    urls = ["https://github.com/madler/zlib/archive/v1.2.13.tar.gz"],
)
```

### third_party/zlib.BUILD

```starlark
load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")

filegroup(
    name = "all",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)

cmake(
    name = "zlib",
    cache_entries = {
        "CMAKE_BUILD_TYPE": "Release",
    },
    lib_source = ":all",
    out_static_libs = ["libz.a"],
    visibility = ["//visibility:public"],
)
```

## More Examples

For more complete examples, see the [examples directory](https://github.com/bazel-contrib/rules_foreign_cc/tree/main/examples) in the rules_foreign_cc repository.
