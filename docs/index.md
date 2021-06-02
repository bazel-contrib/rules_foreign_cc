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

To use the ForeignCc build rules, add the following content to your WORKSPACE file:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_foreign_cc",
    sha256 = "d54742ffbdc6924f222d2179f0e10e911c5c659c4ae74158e9fe827aad862ac6",
    strip_prefix = "rules_foreign_cc-0.2.0",
    url = "https://github.com/bazelbuild/rules_foreign_cc/archive/0.2.0.tar.gz",
)

load("@rules_foreign_cc//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")

rules_foreign_cc_dependencies()
```

Please note that there are many different configuration options for
[rules_foreign_cc_dependencies](./flatten.md#rules_foreign_cc_dependencies)
which offer more control over the toolchains used during the build phase. Please see
that macro's documentation for more details.

## Rules

- [cmake](./cmake.md)
- [configure_make](./configure_make.md)
- [make](./make.md)
- [ninja](./ninja.md)

For additional rules/macros/providers, see the [full API in one page](./flatten.md).
