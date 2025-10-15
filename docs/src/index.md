# Rules ForeignCc

Rules for building C/C++ projects using foreign build systems (non Bazel) inside Bazel projects.

## Overview

Rules ForeignCc is designed to help users build projects that are not built by Bazel and also
not fully under their control (ie: large and mature open source software). These rules provide
a mechanism to build these external projects within Bazel's sandbox environment using a variety
of C/C++ build systems to be later consumed by other rules as though they were normal [cc][cc]
rules.

[cc]: https://docs.bazel.build/versions/master/be/c-cpp.html

## Setup

rules_foreign_cc supports both modern Bzlmod and legacy WORKSPACE setups.

### Using Bzlmod (Recommended)

To use rules_foreign_cc with Bzlmod, add the following to your `MODULE.bazel` file:

```starlark
bazel_dep(name = "rules_foreign_cc", version = "0.13.0")

# Optional: Configure tool versions
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

For more details on Bzlmod support and customizing tool versions, see the [Bzlmod Support](bzlmod.md) page.

### Using WORKSPACE (Legacy)

To use the ForeignCc build rules with WORKSPACE, add the following content to your WORKSPACE file:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_foreign_cc",
    # TODO: Get the latest sha256 value from a bazel debug message or the latest
    #       release on the releases page: https://github.com/bazel-contrib/rules_foreign_cc/releases
    #
    # integrity = "...",
    strip_prefix = "rules_foreign_cc-{release_archive}",
    url = "https://github.com/bazel-contrib/rules_foreign_cc/archive/{release_archive}.tar.gz",
)

load("@rules_foreign_cc//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")

rules_foreign_cc_dependencies()
```

Please note that there are many different configuration options for
[rules_foreign_cc_dependencies](./flatten.md#rules_foreign_cc_dependencies)
which offer more control over the toolchains used during the build phase. Please see
that macro's documentation for more details.

If you're migrating from WORKSPACE to Bzlmod, see the [Migration Guide](migration.md).
