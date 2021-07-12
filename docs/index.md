# Rules ForeignCc

Rules for building C/C++ projects using foreign build systems (non Bazel) inside Bazel projects.

| Release | Commit | Status |
| --- | --------- | --- |
| {release} | [{short_commit}](https://github.com/bazelbuild/rules_foreign_cc/commit/{commit}) | [![Build status](https://badge.buildkite.com/c28afbf846e2077715c753dda1f4b820cdcc46cc6cde16503c.svg?branch=main)](https://buildkite.com/bazel/rules-foreign-cc/builds?branch=main) |

## Overview

Rules ForeignCc is designed to help users build projects that are not built by Bazel and also
not fully under their control (ie: large and mature open source software). These rules provide
a mechanism to build these external projects within Bazel's sandbox environment using a variety
of C/C++ build systems to be later consumed by other rules as though they were normal [cc][cc]
rules.

[cc]: https://docs.bazel.build/versions/master/be/c-cpp.html

## Setup

To use the ForeignCc build rules, add the following content to your WORKSPACE file:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_foreign_cc",
    # TODO: Get the latest sha256 value from a bazel debug message or the latest 
    #       release on the releases page: https://github.com/bazelbuild/rules_foreign_cc/releases
    #
    # sha256 = "...",
    strip_prefix = "rules_foreign_cc-{release_archive}",
    url = "https://github.com/bazelbuild/rules_foreign_cc/archive/{release_archive}.tar.gz",
)

load("@rules_foreign_cc//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")

rules_foreign_cc_dependencies()
```

Please note that there are many different configuration options for
[rules_foreign_cc_dependencies](./flatten.md#rules_foreign_cc_dependencies)
which offer more control over the toolchains used during the build phase. Please see
that macro's documentation for more details.
