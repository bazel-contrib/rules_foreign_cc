# Bzlmod Support

rules_foreign_cc provides full support for Bazel's modern dependency management system, Bzlmod. This page describes how to use rules_foreign_cc with Bzlmod and how to configure toolchain versions.

## Basic Setup

To use rules_foreign_cc with Bzlmod, add the following to your `MODULE.bazel` file:

```starlark
bazel_dep(name = "rules_foreign_cc", version = "0.13.0")
```

The rules will automatically register default toolchains with the following versions:

- CMake: 3.31.8
- Make: 4.4.1
- Meson: 1.5.1
- Ninja: 1.13.0
- pkg-config: 0.29.2

## Customizing Toolchain Versions

If you need to use specific versions of the build tools, you can configure them using the `tools` module extension:

### CMake Version

```starlark
bazel_dep(name = "rules_foreign_cc", version = "0.13.0")

tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.cmake(version = "3.30.5")
```

### Multiple Tool Versions

You can configure multiple tools at once:

```starlark
bazel_dep(name = "rules_foreign_cc", version = "0.13.0")

tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.cmake(version = "3.30.5")
tools.ninja(version = "1.12.0")
tools.make(version = "4.4.1")
tools.meson(version = "1.5.1")
tools.pkgconfig(version = "0.29.2")
```

## Available Tool Tags

The `tools` module extension supports the following tag classes:

### `cmake`

Configure the CMake toolchain version.

**Attributes:**
- `version` (string, optional): The CMake version. Default: `3.31.8`

### `ninja`

Configure the Ninja toolchain version.

**Attributes:**
- `version` (string, optional): The Ninja version. Default: `1.13.0`

### `make`

Configure the GNU Make toolchain version.

**Attributes:**
- `version` (string, optional): The GNU Make version. Default: `4.4.1`

### `meson`

Configure the Meson toolchain version.

**Attributes:**
- `version` (string, optional): The Meson version. Default: `1.5.1`

### `pkgconfig`

Configure the pkg-config toolchain version.

**Attributes:**
- `version` (string, optional): The pkg-config version. Default: `0.29.2`

## Supported Versions

rules_foreign_cc provides pre-configured toolchains for a wide range of tool versions. Here are the currently supported versions:

### CMake

Supported versions range from `3.19.0` to `4.0.3`. See [toolchains/cmake_versions.bzl](https://github.com/bazel-contrib/rules_foreign_cc/blob/main/toolchains/cmake_versions.bzl) for the complete list of available versions.

### Other Tools

For the complete list of supported versions for other tools, please refer to:
- Make: Check `foreign_cc/repositories.bzl` for supported versions
- Ninja: Check `foreign_cc/repositories.bzl` for supported versions
- Meson: Check `foreign_cc/repositories.bzl` for supported versions
- pkg-config: Check `foreign_cc/repositories.bzl` for supported versions

## Registering Toolchains

When using the module extension, toolchains are automatically registered for you. You'll need to register them in your MODULE.bazel:

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

## How It Works

The module extension works by:

1. Reading the tool version tags from your MODULE.bazel
2. Downloading or building the specified versions of the tools
3. Creating toolchain definitions for each tool
4. Registering these toolchains via the `toolchain_hub` repository

Both prebuilt binaries (where available) and built-from-source versions are configured, with prebuilt versions taking priority for faster builds.

## Troubleshooting

### Tool version not found

If you specify a version that isn't supported, the build will fail with an error message. Check the supported versions in the source files mentioned above.

### Toolchain resolution issues

If you're experiencing toolchain resolution problems, you can debug them using:

```bash
bazel query --output=build @toolchain_hub//:all
```

This will show you which toolchains were registered by the extension.

## Migration from WORKSPACE

See the [Migration Guide](#migration-from-workspace) below for details on migrating from WORKSPACE-based setup to Bzlmod.
