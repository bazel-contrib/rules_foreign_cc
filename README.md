# rules_foreign_cc

Rules for building C/C++ projects using foreign build systems inside Bazel projects.

* Experimental - API will most definitely change.
* This is not an officially supported Google product
(meaning, support and/or new releases may be limited.)

## ./configure && make

**NOTE**: this requires building Bazel from head after https://github.com/bazelbuild/bazel/commit/6d4cc4c910a92c9de664ef99b7b2c3681f8d9cf1

It also requires passing Bazel the following flag:
```
--experimental_cc_skylark_api_enabled_packages=tools/build_defs
```

## building CMake projects:

- build libraries/binaries with CMake from sources using cmake_external rule
- use cmake_external targets in cc_library, cc_binary targets as dependency
- Bazel cc_toolchain parameters are used inside cmake_external build
- see full list of cmake_external arguments below example
- cmake_external is defined in ./tools/build_defs

**Example:**
(Please see full examples in ./framework_example)

* In `WORKSPACE`, we use a `new_http_archive` to download tarballs with the libraries we use.
* In `BUILD`, we instantiate a `cmake_external` rule which behaves similarly to a `cc_library`, which can then be used in a C++ rule (`cc_binary` in this case).

In `WORKSPACE`, put

```python
new_http_archive(
    name = "zlib",
    build_file_content = all_content,
    sha256 = "4ff941449631ace0d4d203e3483be9dbc9da454084111f97ea0a2114e19bf066",
    strip_prefix = "zlib-1.2.11",
    urls = [
        "https://zlib.net/zlib-1.2.11.tar.xz",
    ],
)
```

and in `BUILD`, put

```python
load("//tools/build_defs:cmake.bzl", "cmake_external")

cmake_external(
    name = "libz",
    lib_source = "@zlib//:all",
)

cc_binary(
    name = "zlib_usage_example",
    srcs = ["zlib-example.cpp"],
    deps = [":libz"],
)
```

then build as usual:

```bash
$ devbazel build //:libevent_echosrv1
```

**cmake_external arguments:**

```python
attrs: {
    # cmake_options - (list of strings) options to be passed to the cmake call
    "cmake_options": attr.string_list(mandatory = False, default = [])
    # Library name. Defines the name of the install directory and the name of the static library,
    # if no output files parameters are defined (any of static_libraries, shared_libraries,
    # interface_libraries, binaries_names)
    # Optional. If not defined, defaults to the target's name.
    "lib_name": attr.string(mandatory = False),
    # Label with source code to build. Typically a filegroup for the source of remote repository.
    # Mandatory.
    "lib_source": attr.label(mandatory = True, allow_files = True),
    # Optional compilation definitions to be passed to the dependencies of this library.
    # They are NOT passed to the compiler, you should duplicate them in the configuration options.
    "defines": attr.string_list(mandatory = False, default = []),
    #
    # Optional additional inputs to be declared as needed for the shell script action.
    # Not used by the shell script part in cc_external_rule_impl.
    "additional_inputs": attr.label_list(mandatory = False, allow_files = True, default = []),
    # Optional additional tools needed for the building.
    # Not used by the shell script part in cc_external_rule_impl.
    "additional_tools": attr.label_list(mandatory = False, allow_files = True, default = []),
    #
    # Optional part of the shell script to be added after the make commands
    "postfix_script": attr.string(mandatory = False),
    # Optinal make commands, defaults to ["make", "make install"]
    "make_commands": attr.string_list(mandatory = False, default = ["make", "make install"]),
    #
    # Optional dependencies to be copied into the directory structure.
    # Typically those directly required for the external building of the library/binaries.
    # (i.e. those that the external buidl system will be looking for and paths to which are
    # provided by the calling rule)
    "deps": attr.label_list(mandatory = False, allow_files = True, default = []),
    # Optional tools to be copied into the directory structure.
    # Similar to deps, those directly required for the external building of the library/binaries.
    "tools_deps": attr.label_list(mandatory = False, allow_files = True, default = []),
    #
    # Optional name of the output subdirectory with the header files, defaults to 'include'.
    "out_include_dir": attr.string(mandatory = False, default = "include"),
    # Optional name of the output subdirectory with the library files, defaults to 'lib'.
    "out_lib_dir": attr.string(mandatory = False, default = "lib"),
    # Optional name of the output subdirectory with the binary files, defaults to 'bin'.
    "out_bin_dir": attr.string(mandatory = False, default = "bin"),
    #
    # Optional. if true, link all the object files from the static library,
    # even if they are not used.
    "alwayslink": attr.bool(mandatory = False, default = False),
    # Optional link options to be passed up to the dependencies of this library
    "linkopts": attr.string_list(mandatory = False, default = []),
    #
    # Output files names parameters. If any of them is defined, only these files are passed to
    # Bazel providers.
    # if no of them is defined, default lib_name.a/lib_name.lib static library is assumed.
    #
    # Optional names of the resulting static libraries.
    "static_libraries": attr.string_list(mandatory = False),
    # Optional names of the resulting shared libraries.
    "shared_libraries": attr.string_list(mandatory = False),
    # Optional names of the resulting interface libraries.
    "interface_libraries": attr.string_list(mandatory = False),
    # Optional names of the resulting binaries.
    "binaries": attr.string_list(mandatory = False),
    #
    # Optional name of the output subdirectory with pkgconfig files.
    "out_pkg_config_dir": attr.string(mandatory = False),
  }
```