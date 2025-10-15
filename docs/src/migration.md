# Migration from WORKSPACE to Bzlmod

This guide helps you migrate your rules_foreign_cc setup from WORKSPACE to MODULE.bazel.

## Overview

Bzlmod is Bazel's modern dependency management system that offers several advantages over WORKSPACE:

- Automatic dependency resolution
- Better version conflict handling
- Simpler configuration
- Module extensions for advanced customization

## Basic Migration

### Before (WORKSPACE)

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_foreign_cc",
    sha256 = "...",
    strip_prefix = "rules_foreign_cc-0.13.0",
    url = "https://github.com/bazel-contrib/rules_foreign_cc/releases/download/0.13.0/rules_foreign_cc-0.13.0.tar.gz",
)

load("@rules_foreign_cc//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")

rules_foreign_cc_dependencies()
```

### After (MODULE.bazel)

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

## Migrating Custom Tool Versions

### Before (WORKSPACE)

If you were specifying custom tool versions in WORKSPACE:

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_foreign_cc",
    # ... archive configuration
)

load("@rules_foreign_cc//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")

rules_foreign_cc_dependencies(
    cmake_version = "3.30.5",
    ninja_version = "1.12.0",
    make_version = "4.4.1",
    meson_version = "1.5.1",
    pkgconfig_version = "0.29.2",
)
```

### After (MODULE.bazel)

With Bzlmod, you configure tool versions using the module extension:

```starlark
bazel_dep(name = "rules_foreign_cc", version = "0.13.0")

tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
tools.cmake(version = "3.30.5")
tools.ninja(version = "1.12.0")
tools.make(version = "4.4.1")
tools.meson(version = "1.5.1")
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

## Migrating Advanced Configurations

### Preinstalled Tools

If you were using `register_preinstalled_tools` in WORKSPACE:

#### Before (WORKSPACE)

```starlark
rules_foreign_cc_dependencies(
    register_preinstalled_tools = True,
    register_built_tools = False,
)
```

#### After (MODULE.bazel)

The Bzlmod extension always registers built-from-source toolchains, but you can still register native toolchains separately:

```starlark
bazel_dep(name = "rules_foreign_cc", version = "0.13.0")

# Configure tool versions
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
    # These will prefer prebuilt binaries when available
    "@prebuilt_cmake_toolchains//:all",
    "@prebuilt_ninja_toolchains//:all",
    "@rules_foreign_cc_framework_toolchains//:all",
    "@toolchain_hub//:all",
    # Register native toolchains with lower priority
    "@rules_foreign_cc//toolchains:all",
)
```

### Built-from-Source Tools

If you were using `register_built_tools`:

#### Before (WORKSPACE)

```starlark
rules_foreign_cc_dependencies(
    register_built_tools = True,
    cmake_version = "3.30.5",
)
```

#### After (MODULE.bazel)

This is the default behavior with the module extension:

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

## Common Pitfalls

### Missing use_repo

Don't forget to add `use_repo()` after using the extension. Without it, the repositories won't be visible to your build.

**Error:**
```
ERROR: Repository '@prebuilt_cmake_toolchains' is not visible from...
```

**Solution:**
Add the `use_repo()` call with all necessary repositories.

### Missing register_toolchains

The module extension creates toolchains but doesn't automatically register them. You must explicitly register them in your MODULE.bazel.

**Error:**
```
No matching toolchains found for types @rules_foreign_cc//toolchains:cmake_toolchain
```

**Solution:**
Add the `register_toolchains()` calls for all the repositories created by the extension.

### Version Not Available

If you specify a tool version that isn't supported:

**Error:**
```
Error in cmake_toolchains: No cmake toolchain available for version X.Y.Z
```

**Solution:**
Check the available versions in the rules_foreign_cc repository:
- CMake: `toolchains/cmake_versions.bzl`
- Other tools: Check `foreign_cc/repositories.bzl` and the built toolchains files

## Step-by-Step Migration Checklist

1. Enable Bzlmod in your `.bazelrc`:
   ```
   common --enable_bzlmod
   ```

2. Create or update your `MODULE.bazel` file

3. Add the `rules_foreign_cc` dependency:
   ```starlark
   bazel_dep(name = "rules_foreign_cc", version = "0.13.0")
   ```

4. Configure tool versions if needed (optional):
   ```starlark
   tools = use_extension("@rules_foreign_cc//foreign_cc:extensions.bzl", "tools")
   tools.cmake(version = "3.30.5")
   ```

5. Add `use_repo()` to make extension repositories visible:
   ```starlark
   use_repo(
       tools,
       "prebuilt_cmake_toolchains",
       "prebuilt_ninja_toolchains",
       "rules_foreign_cc_framework_toolchains",
       "toolchain_hub",
   )
   ```

6. Register toolchains:
   ```starlark
   register_toolchains(
       "@prebuilt_cmake_toolchains//:all",
       "@prebuilt_ninja_toolchains//:all",
       "@rules_foreign_cc_framework_toolchains//:all",
       "@toolchain_hub//:all",
   )
   ```

7. Test your build:
   ```bash
   bazel build //...
   ```

8. Remove WORKSPACE configuration (or keep both for a transition period)

## Maintaining Both WORKSPACE and MODULE.bazel

During migration, you can maintain both WORKSPACE and MODULE.bazel configurations. Bazel will use MODULE.bazel when Bzlmod is enabled and fall back to WORKSPACE otherwise.

```bash
# Build with Bzlmod
bazel build --enable_bzlmod //...

# Build with WORKSPACE
bazel build --noenable_bzlmod //...
```

## Getting Help

If you encounter issues during migration:

1. Check the [Bzlmod documentation](bzlmod.md) for detailed information about the module extension
2. Review the [examples/MODULE.bazel](https://github.com/bazel-contrib/rules_foreign_cc/blob/main/examples/MODULE.bazel) for a working example
3. File an issue at https://github.com/bazel-contrib/rules_foreign_cc/issues
