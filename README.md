# rules_foreign_cc

[![Build status](https://badge.buildkite.com/c28afbf846e2077715c753dda1f4b820cdcc46cc6cde16503c.svg?branch=main)](https://buildkite.com/bazel/rules-foreign-cc?branch=main)

**Rules for building C/C++ projects using foreign build systems inside Bazel projects.**

This is **not an officially supported Google product**
(meaning, support and/or new releases may be limited.)

## Documentation

Documentation for all rules and providers are available [here](./docs/README.md)

## Bazel versions compatibility

Works with Bazel after 3.4.0 without any flags.

Note that the rules may be compatible with older versions of Bazel but support may break
in future changes as these older versions are not tested.

## News

**March 2019:**

- Support for versions earlier then 0.22 was removed.

- Tests on Bazel CI are running in the nested workspace

**January 2019:**

- Bazel 0.22.0 is released, no flags are needed for this version, but it does not work on Windows (Bazel C++ API is broken).

- Support for versions earlier then 0.20 was removed.

- [rules_foreign_cc take-aways](https://docs.google.com/document/d/1ZVvzvkUVTkPCzI-2z4S4VrSNu4kdaBknz7UnK8vaoZU/edit?usp=sharing) describing the recent work has been published.

- Examples package became the separate workspace.
  This also allows to illustrate how to initialize rules_foreign_cc.

- Native tools (cmake, ninja) toolchains were introduced.
  Though the user code does not have to be changed (default toolchains are registered, they call the preinstalled binaries by name.),
  you may simplify usage of ninja with the cmake_external rule and call it just by name.
  Please see examples/cmake_nghttp2 for ninja usage, and WORKSPACE and BUILD files in examples for the native tools toolchains usage
  (the locally preinstalled tools are registered by default, the build as part of the build tools are used in examples).
  Also, in examples/with_prebuilt_ninja_artefact you can see how to download and use prebuilt artifact.

- Shell script parts were extracted into a separate toolchain.
  Shell script inside framework.bzl is first created with special notations:

      - 'export var_name=var_value' for defining the environment variable
      - '$$var_name$$' for referencing environment variable
      - 'shell_command <space-separated-maybe-quoted-arguments>' for calling shell fragment

  The created script is further processed to get the real shell script with shell parts either
  replaced with actual fragments or with shell function calls (functions are added into the beginning of the script).
  Extracted shell fragments are described in commands.bzl.

  Further planned steps in this direction: testing with RBE, shell script fragments for running on Windows without msys/mingw,
  tests for shell fragments.

## Building CMake projects

- Build libraries/binaries with CMake from sources using cmake_external rule
- Use cmake_external targets in cc_library, cc_binary targets as dependency
- Bazel cc_toolchain parameters are used inside cmake_external build
- See full list of cmake_external arguments below 'example'
- cmake_external is defined in ./tools/build_defs
- Works on Ubuntu, Mac OS and Windows(\* see special notes below in Windows section) operating systems

**Example:**
(Please see full examples in ./examples)

The example for **Windows** is below, in the section 'Usage on Windows'.

- In `WORKSPACE`, we use a `http_archive` to download tarballs with the libraries we use.
- In `BUILD`, we instantiate a `cmake_external` rule which behaves similarly to a `cc_library`, which can then be used in a C++ rule (`cc_binary` in this case).

In `WORKSPACE`, put

```python
workspace(name = "rules_foreign_cc_usage_example")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Group the sources of the library so that CMake rule have access to it
all_content = """filegroup(name = "all", srcs = glob(["**"]), visibility = ["//visibility:public"])"""

# Rule repository
http_archive(
   name = "rules_foreign_cc",
   strip_prefix = "rules_foreign_cc-main",
   url = "https://github.com/bazelbuild/rules_foreign_cc/archive/main.zip",
)

load("@rules_foreign_cc//:workspace_definitions.bzl", "rules_foreign_cc_dependencies")

# Call this function from the WORKSPACE file to initialize rules_foreign_cc
#  dependencies and let neccesary code generation happen
#  (Code generation is needed to support different variants of the C++ Starlark API.).
#
#  Args:
#    native_tools_toolchains: pass the toolchains for toolchain types
#      '@rules_foreign_cc//tools/build_defs:make_toolchain',
#      '@rules_foreign_cc//tools/build_defs:cmake_toolchain' and
#      '@rules_foreign_cc//tools/build_defs:ninja_toolchain' with the needed platform constraints.
#      If you do not pass anything, registered default toolchains will be selected (see below).
#
#    register_default_tools: if True, the make, cmake and ninja toolchains, calling corresponding
#      preinstalled binaries by name (make, cmake, ninja) will be registered after
#      'native_tools_toolchains' without any platform constraints.
#      The default is True.
rules_foreign_cc_dependencies([
    "//:my_make_toolchain",
    "//:my_cmake_toolchain",
    "//:my_ninja_toolchain",
])

# OpenBLAS source code repository
http_archive(
   name = "openblas",
   build_file_content = all_content,
   strip_prefix = "OpenBLAS-0.3.2",
   urls = ["https://github.com/xianyi/OpenBLAS/archive/v0.3.2.tar.gz"],
)

# Eigen source code repository
http_archive(
   name = "eigen",
   build_file_content = all_content,
   strip_prefix = "eigen-git-mirror-3.3.5",
   urls = ["https://github.com/eigenteam/eigen-git-mirror/archive/3.3.5.tar.gz"],
)
```

and in `BUILD`, put

```python
load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

cmake_external(
   name = "openblas",
   # Values to be passed as -Dkey=value on the CMake command line;
   # here are serving to provide some CMake script configuration options
   cache_entries = {
       "NOFORTRAN": "on",
       "BUILD_WITHOUT_LAPACK": "no",
   },
   lib_source = "@openblas//:all",

   # We are selecting the resulting static library to be passed in C/C++ provider
   # as the result of the build;
   # However, the cmake_external dependants could use other artefacts provided by the build,
   # according to their CMake script
   static_libraries = ["libopenblas.a"],
)

cmake_external(
   name = "eigen",
   # These options help CMake to find prebuilt OpenBLAS, which will be copied into
   # $EXT_BUILD_DEPS/openblas by the cmake_external script
   cache_entries = {
       "BLA_VENDOR": "OpenBLAS",
       "BLAS_LIBRARIES": "$EXT_BUILD_DEPS/openblas/lib/libopenblas.a",
   },
   headers_only = True,
   lib_source = "@eigen//:all",
   # Dependency on other cmake_external rule; can also depend on cc_import, cc_library rules
   deps = [":openblas"],
)
```

then build as usual:

```bash
$ devbazel build //examples/cmake_pcl:eigen
```

**Usage on Windows**

When using on Windows, you should start Bazel in MSYS2 shell, as the shell script inside cmake_external assumes this.
Also, you should explicitly specify **make commands and option to generate CMake crosstool file**.

The default generator for CMake will be detected automatically, or you can specify it explicitly.

**The tested generators:** Visual Studio 15, Ninja and NMake.
The extension '.lib' is assumed for the static libraries by default.

Example usage (see full example in ./examples/cmake_hello_world_lib):
Example assumes that MS Visual Studio and Ninja are installed on the host machine, and Ninja bin directory is added to PATH.

```python
cmake_external(
    # expect to find ./lib/hello.lib as the result of the build
    name = "hello",
    # This option can be omitted
    cmake_options = ["-G \"Visual Studio 15 2017 Win64\""],
    generate_crosstool_file = True,
    lib_source = ":srcs",
    # .vcxproj or .sln file must be specified argument, as multiple files are generated by CMake
    make_commands = ["MSBuild.exe INSTALL.vcxproj"],
)

cmake_external(
    name = "hello_ninja",
    # expect to find ./lib/hello.lib as the result of the build
    lib_name = "hello",
    # explicitly specify the generator
    cmake_options = ["-GNinja"],
    generate_crosstool_file = True,
    lib_source = ":srcs",
    # specify to call ninja after configuring
    make_commands = [
        "ninja",
        "ninja install",
    ],
)

cmake_external(
    name = "hello_nmake",
    # explicitly specify the generator
    cmake_options = ["-G \"NMake Makefiles\""],
    generate_crosstool_file = True,
    lib_source = ":srcs",
    # specify to call nmake after configuring
    make_commands = [
        "nmake",
        "nmake install",
    ],
    # expect to find ./lib/hello.lib as the result of the build
    static_libraries = ["hello.lib"]
)
```

## Design document

[External C/C++ libraries rules](https://docs.google.com/document/d/1Gv452Vtki8edo_Dj9VTNJt5DA_lKTcSMwrwjJOkLaoU/edit?usp=sharing)
