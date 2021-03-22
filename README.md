# rules_foreign_cc

[![Build status](https://badge.buildkite.com/c28afbf846e2077715c753dda1f4b820cdcc46cc6cde16503c.svg?branch=main)](https://buildkite.com/bazel/rules-foreign-cc?branch=main)

**Rules for building C/C++ projects using foreign build systems inside Bazel projects.**

This is **not an officially supported Google product**
(meaning, support and/or new releases may be limited.)

## Documentation

Documentation for all rules and providers are available [here](./docs/README.md)

## Bazel versions compatibility

Works with Bazel after 3.7.0 without any flags.

Note that the rules may be compatible with older versions of Bazel but support may break
in future changes as these older versions are not tested.

## News

For more generalized updates, please see [NEWS.md](./NEWS.md) or checkout the
[release notes](https://github.com/bazelbuild/rules_foreign_cc/releases) of current or previous releases

## Building CMake projects

- Build libraries/binaries with CMake from sources using cmake rule
- Use cmake targets in [cc_library][ccl], [cc_binary][ccb] targets as dependency
- Bazel [cc_toolchain][cct] parameters are used inside cmake build
- See full list of cmake arguments below 'example'
- cmake is defined in `./tools/build_defs`
- Works on Ubuntu, Mac OS and Windows(\* see special notes below in Windows section) operating systems

**Example:**
(Please see full examples in ./examples)

The example for **Windows** is below, in the section 'Usage on Windows'.

- In `WORKSPACE.bazel`, we use a `http_archive` to download tarballs with the libraries we use.
- In `BUILD.bazel`, we instantiate a `cmake` rule which behaves similarly to a [cc_library][ccl], which can then be used in a C++ rule ([cc_binary][ccb] in this case).

In `WORKSPACE.bazel`, put

```python
workspace(name = "rules_foreign_cc_usage_example")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Rule repository, note that it's recommended to use a pinned commit to a released version of the rules
http_archive(
   name = "rules_foreign_cc",
   sha256 = "c2cdcf55ffaf49366725639e45dedd449b8c3fe22b54e31625eb80ce3a240f1e",
   strip_prefix = "rules_foreign_cc-0.1.0",
   url = "https://github.com/bazelbuild/rules_foreign_cc/archive/0.1.0.zip",
)

load("@rules_foreign_cc//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")

# This sets up some common toolchains for building targets. For more details, please see
# https://github.com/bazelbuild/rules_foreign_cc/tree/main/docs#rules_foreign_cc_dependencies
rules_foreign_cc_dependencies()

_ALL_CONTENT = """\
filegroup(
    name = "all_srcs",
    srcs = glob(["**"]),
    visibility = ["//visibility:public],
)
"""

# pcre source code repository
http_archive(
    name = "pcre",
    build_file_content = _ALL_CONTENT,
    strip_prefix = "pcre-8.43",
    urls = [
        "https://mirror.bazel.build/ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz",
        "https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz",
    ],
    sha256 = "0b8e7465dc5e98c757cc3650a20a7843ee4c3edf50aaf60bb33fd879690d2c73",
)
```

And in the `BUILD.bazel` file, put:

```python
load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")

cmake(
    name = "pcre",
    cache_entries = {
        "CMAKE_C_FLAGS": "-fPIC",
    },
    lib_source = "@pcre//:all_srcs",
    out_static_libs = ["libpcre.a"],
)
```

then build as usual:

```bash
bazel build //:pcre
```

**Usage on Windows**

When using on Windows, you should start Bazel in MSYS2 shell, as the shell script inside cmake assumes this.
Also, you should explicitly specify **make commands and option to generate CMake crosstool file**.

The default generator for CMake will be detected automatically, or you can specify it explicitly.

**The tested generators:** Visual Studio 15, Ninja and NMake.
The extension `.lib` is assumed for the static libraries by default.

Example usage (see full example in `./examples/cmake_hello_world_lib`):
Example assumes that MS Visual Studio and Ninja are installed on the host machine, and Ninja bin directory is added to PATH.

```python
cmake(
    # expect to find ./lib/hello.lib as the result of the build
    name = "hello",
    # This option can be omitted
    generate_args = [
        "-G \"Visual Studio 15 2017\"",
        "-A Win64",
    ],
    lib_source = ":srcs",
)

cmake(
    name = "hello_ninja",
    # expect to find ./lib/hello.lib as the result of the build
    lib_name = "hello",
    # explicitly specify the generator
    generate_args = ["-GNinja"],
    lib_source = ":srcs",
)

cmake(
    name = "hello_nmake",
    # explicitly specify the generator
    generate_args = ["-G \"NMake Makefiles\""],
    lib_source = ":srcs",
    # expect to find ./lib/hello.lib as the result of the build
    out_static_libs = ["hello.lib"],
)
```

## Design document

[External C/C++ libraries rules](https://docs.google.com/document/d/1Gv452Vtki8edo_Dj9VTNJt5DA_lKTcSMwrwjJOkLaoU/edit?usp=sharing)

[ccb]: https://docs.bazel.build/versions/master/be/c-cpp.html#cc_binary
[ccl]: https://docs.bazel.build/versions/master/be/c-cpp.html#cc_library
[cct]: https://docs.bazel.build/versions/master/be/c-cpp.html#cc_toolchain
