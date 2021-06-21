<!-- Generated with Stardoc: http://skydoc.bazel.build -->

# CMake

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
    visibility = ["//visibility:public"],
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

[ccb]: https://docs.bazel.build/versions/master/be/c-cpp.html#cc_binary
[ccl]: https://docs.bazel.build/versions/master/be/c-cpp.html#cc_library
[cct]: https://docs.bazel.build/versions/master/be/c-cpp.html#cc_toolchain


<a id="#cmake"></a>

## cmake

<pre>
cmake(<a href="#cmake-name">name</a>, <a href="#cmake-additional_inputs">additional_inputs</a>, <a href="#cmake-additional_tools">additional_tools</a>, <a href="#cmake-alwayslink">alwayslink</a>, <a href="#cmake-build_args">build_args</a>, <a href="#cmake-build_data">build_data</a>, <a href="#cmake-cache_entries">cache_entries</a>,
      <a href="#cmake-data">data</a>, <a href="#cmake-defines">defines</a>, <a href="#cmake-deps">deps</a>, <a href="#cmake-env">env</a>, <a href="#cmake-generate_args">generate_args</a>, <a href="#cmake-generate_crosstool_file">generate_crosstool_file</a>, <a href="#cmake-install">install</a>, <a href="#cmake-install_args">install_args</a>,
      <a href="#cmake-lib_name">lib_name</a>, <a href="#cmake-lib_source">lib_source</a>, <a href="#cmake-linkopts">linkopts</a>, <a href="#cmake-out_bin_dir">out_bin_dir</a>, <a href="#cmake-out_binaries">out_binaries</a>, <a href="#cmake-out_headers_only">out_headers_only</a>, <a href="#cmake-out_include_dir">out_include_dir</a>,
      <a href="#cmake-out_interface_libs">out_interface_libs</a>, <a href="#cmake-out_lib_dir">out_lib_dir</a>, <a href="#cmake-out_shared_libs">out_shared_libs</a>, <a href="#cmake-out_static_libs">out_static_libs</a>, <a href="#cmake-postfix_script">postfix_script</a>, <a href="#cmake-targets">targets</a>,
      <a href="#cmake-tool_prefix">tool_prefix</a>, <a href="#cmake-tools_deps">tools_deps</a>, <a href="#cmake-working_directory">working_directory</a>)
</pre>

Rule for building external library with CMake.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cmake-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="cmake-additional_inputs"></a>additional_inputs |  __deprecated__: Please use the <code>build_data</code> attribute.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="cmake-additional_tools"></a>additional_tools |  __deprecated__: Please use the <code>build_data</code> attribute.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="cmake-alwayslink"></a>alwayslink |  Optional. if true, link all the object files from the static library, even if they are not used.   | Boolean | optional | False |
| <a id="cmake-build_args"></a>build_args |  Arguments for the CMake build command   | List of strings | optional | [] |
| <a id="cmake-build_data"></a>build_data |  Files needed by this rule only during build/compile time. May list file or rule targets. Generally allows any target.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="cmake-cache_entries"></a>cache_entries |  CMake cache entries to initialize (they will be passed with <code>-Dkey=value</code>) Values, defined by the toolchain, will be joined with the values, passed here. (Toolchain values come first)   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="cmake-data"></a>data |  Files needed by this rule at runtime. May list file or rule targets. Generally allows any target.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="cmake-defines"></a>defines |  Optional compilation definitions to be passed to the dependencies of this library. They are NOT passed to the compiler, you should duplicate them in the configuration options.   | List of strings | optional | [] |
| <a id="cmake-deps"></a>deps |  Optional dependencies to be copied into the directory structure. Typically those directly required for the external building of the library/binaries. (i.e. those that the external buidl system will be looking for and paths to which are provided by the calling rule)   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="cmake-env"></a>env |  Environment variables to set during the build. <code>$(execpath)</code> macros may be used to point at files which are listed as <code>data</code>, <code>deps</code>, or <code>build_data</code>, but unlike with other rules, these will be replaced with absolute paths to those files, because the build does not run in the exec root. No other macros are supported.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="cmake-generate_args"></a>generate_args |  Arguments for CMake's generate command. Arguments should be passed as key/value pairs. eg: <code>["-G Ninja", "--debug-output", "-DFOO=bar"]</code>. Note that unless a generator (<code>-G</code>) argument is provided, the default generators are [Unix Makefiles](https://cmake.org/cmake/help/latest/generator/Unix%20Makefiles.html) for Linux and MacOS and [Ninja](https://cmake.org/cmake/help/latest/generator/Ninja.html) for Windows.   | List of strings | optional | [] |
| <a id="cmake-generate_crosstool_file"></a>generate_crosstool_file |  When True, CMake crosstool file will be generated from the toolchain values, provided cache-entries and env_vars (some values will still be passed as <code>-Dkey=value</code> and environment variables). If <code>CMAKE_TOOLCHAIN_FILE</code> cache entry is passed, specified crosstool file will be used When using this option to cross-compile, it is required to specify <code>CMAKE_SYSTEM_NAME</code> in the cache_entries   | Boolean | optional | True |
| <a id="cmake-install"></a>install |  If True, the <code>cmake --install</code> comand will be performed after a build   | Boolean | optional | True |
| <a id="cmake-install_args"></a>install_args |  Arguments for the CMake install command   | List of strings | optional | [] |
| <a id="cmake-lib_name"></a>lib_name |  Library name. Defines the name of the install directory and the name of the static library, if no output files parameters are defined (any of static_libraries, shared_libraries, interface_libraries, binaries_names) Optional. If not defined, defaults to the target's name.   | String | optional | "" |
| <a id="cmake-lib_source"></a>lib_source |  Label with source code to build. Typically a filegroup for the source of remote repository. Mandatory.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="cmake-linkopts"></a>linkopts |  Optional link options to be passed up to the dependencies of this library   | List of strings | optional | [] |
| <a id="cmake-out_bin_dir"></a>out_bin_dir |  Optional name of the output subdirectory with the binary files, defaults to 'bin'.   | String | optional | "bin" |
| <a id="cmake-out_binaries"></a>out_binaries |  Optional names of the resulting binaries.   | List of strings | optional | [] |
| <a id="cmake-out_headers_only"></a>out_headers_only |  Flag variable to indicate that the library produces only headers   | Boolean | optional | False |
| <a id="cmake-out_include_dir"></a>out_include_dir |  Optional name of the output subdirectory with the header files, defaults to 'include'.   | String | optional | "include" |
| <a id="cmake-out_interface_libs"></a>out_interface_libs |  Optional names of the resulting interface libraries.   | List of strings | optional | [] |
| <a id="cmake-out_lib_dir"></a>out_lib_dir |  Optional name of the output subdirectory with the library files, defaults to 'lib'.   | String | optional | "lib" |
| <a id="cmake-out_shared_libs"></a>out_shared_libs |  Optional names of the resulting shared libraries.   | List of strings | optional | [] |
| <a id="cmake-out_static_libs"></a>out_static_libs |  Optional names of the resulting static libraries. Note that if <code>out_headers_only</code>, <code>out_static_libs</code>, <code>out_shared_libs</code>, and <code>out_binaries</code> are not set, default <code>lib_name.a</code>/<code>lib_name.lib</code> static library is assumed   | List of strings | optional | [] |
| <a id="cmake-postfix_script"></a>postfix_script |  Optional part of the shell script to be added after the make commands   | String | optional | "" |
| <a id="cmake-targets"></a>targets |  A list of targets with in the foreign build system to produce. An empty string (<code>""</code>) will result in a call to the underlying build system with no explicit target set   | List of strings | optional | [] |
| <a id="cmake-tool_prefix"></a>tool_prefix |  A prefix for build commands   | String | optional | "" |
| <a id="cmake-tools_deps"></a>tools_deps |  __deprecated__: Please use the <code>build_data</code> attribute.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="cmake-working_directory"></a>working_directory |  Working directory, with the main CMakeLists.txt (otherwise, the top directory of the lib_source label files is used.)   | String | optional | "" |


