# rules_foreign_cc

[![Build status](https://badge.buildkite.com/c28afbf846e2077715c753dda1f4b820cdcc46cc6cde16503c.svg?branch=main)](https://buildkite.com/bazel/rules-foreign-cc?branch=main)

**Rules for building C/C++ projects using foreign build systems inside Bazel projects.**

This is **not an officially supported Google product**
(meaning, support and/or new releases may be limited.)

## Documentation

Documentation for all rules and providers are available at [the doc site](https://bazel-contrib.github.io/rules_foreign_cc/)

## Version compatibility

### bazel

The intent is to support the latest minor of all `Active` or `Maintenance` [Bazel Versions](https://bazel.build/release).
This generally means that older bazel versions may work, but they won't be tested and so they might break.

### delegated build systems (e.g. cmake, ninja)

Some of these projects don't use semver, but the intent is is to support the logical equivalent of:

- Latest version that is upstream-supported (meaning, they will accept patches for it)
  - If upstream will accept patches for multiple release branches, then the latest patch for each of those will be
        supported.
- Exact version and latest patch version for supported LTS releases of distributions. The idea is that most packages
    only get tested with the versions in the distros, so these are the versions most likely to work.
  - [Ubuntu](https://ubuntu.com/about/release-cycle)
  - [Fedora](https://endoflife.date/fedora)
  - Versions can be referenced from Repology, e.g. [cmake](https://repology.org/project/cmake/versions)

## News

For more generalized updates, please see [NEWS.md](./NEWS.md) or checkout the
[release notes](https://github.com/bazel-contrib/rules_foreign_cc/releases) of current or previous releases

## Design document

[External C/C++ libraries rules](https://docs.google.com/document/d/1Gv452Vtki8edo_Dj9VTNJt5DA_lKTcSMwrwjJOkLaoU/edit?usp=sharing)

## Caveats

- FreeBSD support is currently experimental and on a best-effort basis.
  Google currently doesn't have a CI test environment for FreeBSD,
  but please make your voice heard by upvoting this
  [issue](https://github.com/bazelbuild/continuous-integration/issues/258).
