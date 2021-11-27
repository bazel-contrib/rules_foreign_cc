# rules_foreign_cc

[![Build status](https://badge.buildkite.com/c28afbf846e2077715c753dda1f4b820cdcc46cc6cde16503c.svg?branch=main)](https://buildkite.com/bazel/rules-foreign-cc?branch=main)

**Rules for building C/C++ projects using foreign build systems inside Bazel projects.**

This is **not an officially supported Google product**
(meaning, support and/or new releases may be limited.)

## Documentation

Documentation for all rules and providers are available at: https://bazelbuild.github.io/rules_foreign_cc/

## Bazel versions compatibility

Works with Bazel after 4.0.0 without any flags.

Note that the rules may be compatible with older versions of Bazel but support may break
in future changes as these older versions are not tested.

## News

For more generalized updates, please see [NEWS.md](./NEWS.md) or checkout the
[release notes](https://github.com/bazelbuild/rules_foreign_cc/releases) of current or previous releases

## Design document

[External C/C++ libraries rules](https://docs.google.com/document/d/1Gv452Vtki8edo_Dj9VTNJt5DA_lKTcSMwrwjJOkLaoU/edit?usp=sharing)

[ccb]: https://docs.bazel.build/versions/master/be/c-cpp.html#cc_binary
[ccl]: https://docs.bazel.build/versions/master/be/c-cpp.html#cc_library
[cct]: https://docs.bazel.build/versions/master/be/c-cpp.html#cc_toolchain

## Caveats

* FreeBSD support is currently experimental and on a best-effort basis.
  Google currently doesn't have a CI test environment for FreeBSD,
  but please make your voice heard by upvoting this
  [issue](https://github.com/bazelbuild/continuous-integration/issues/258).
