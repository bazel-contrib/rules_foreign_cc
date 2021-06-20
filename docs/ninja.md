<!-- Generated with Stardoc: http://skydoc.bazel.build -->

A rule for building projects using the [Ninja](https://ninja-build.org/) build tool

<a id="#ninja"></a>

## ninja

<pre>
ninja(<a href="#ninja-name">name</a>, <a href="#ninja-additional_inputs">additional_inputs</a>, <a href="#ninja-additional_tools">additional_tools</a>, <a href="#ninja-alwayslink">alwayslink</a>, <a href="#ninja-args">args</a>, <a href="#ninja-build_data">build_data</a>, <a href="#ninja-data">data</a>, <a href="#ninja-defines">defines</a>, <a href="#ninja-deps">deps</a>,
      <a href="#ninja-directory">directory</a>, <a href="#ninja-env">env</a>, <a href="#ninja-lib_name">lib_name</a>, <a href="#ninja-lib_source">lib_source</a>, <a href="#ninja-linkopts">linkopts</a>, <a href="#ninja-out_bin_dir">out_bin_dir</a>, <a href="#ninja-out_binaries">out_binaries</a>, <a href="#ninja-out_headers_only">out_headers_only</a>,
      <a href="#ninja-out_include_dir">out_include_dir</a>, <a href="#ninja-out_interface_libs">out_interface_libs</a>, <a href="#ninja-out_lib_dir">out_lib_dir</a>, <a href="#ninja-out_shared_libs">out_shared_libs</a>, <a href="#ninja-out_static_libs">out_static_libs</a>,
      <a href="#ninja-postfix_script">postfix_script</a>, <a href="#ninja-targets">targets</a>, <a href="#ninja-tool_prefix">tool_prefix</a>, <a href="#ninja-tools_deps">tools_deps</a>)
</pre>

Rule for building external libraries with [Ninja](https://ninja-build.org/).

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="ninja-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="ninja-additional_inputs"></a>additional_inputs |  __deprecated__: Please use the <code>build_data</code> attribute.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="ninja-additional_tools"></a>additional_tools |  __deprecated__: Please use the <code>build_data</code> attribute.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="ninja-alwayslink"></a>alwayslink |  Optional. if true, link all the object files from the static library, even if they are not used.   | Boolean | optional | False |
| <a id="ninja-args"></a>args |  A list of arguments to pass to the call to <code>ninja</code>   | List of strings | optional | [] |
| <a id="ninja-build_data"></a>build_data |  Files needed by this rule only during build/compile time. May list file or rule targets. Generally allows any target.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="ninja-data"></a>data |  Files needed by this rule at runtime. May list file or rule targets. Generally allows any target.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="ninja-defines"></a>defines |  Optional compilation definitions to be passed to the dependencies of this library. They are NOT passed to the compiler, you should duplicate them in the configuration options.   | List of strings | optional | [] |
| <a id="ninja-deps"></a>deps |  Optional dependencies to be copied into the directory structure. Typically those directly required for the external building of the library/binaries. (i.e. those that the external buidl system will be looking for and paths to which are provided by the calling rule)   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="ninja-directory"></a>directory |  A directory to pass as the <code>-C</code> argument. The rule will always use the root directory of the <code>lib_sources</code> attribute if this attribute is not set   | String | optional | "" |
| <a id="ninja-env"></a>env |  Environment variables to set during the build. <code>$(execpath)</code> macros may be used to point at files which are listed as <code>data</code>, <code>deps</code>, or <code>build_data</code>, but unlike with other rules, these will be replaced with absolute paths to those files, because the build does not run in the exec root. No other macros are supported.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="ninja-lib_name"></a>lib_name |  Library name. Defines the name of the install directory and the name of the static library, if no output files parameters are defined (any of static_libraries, shared_libraries, interface_libraries, binaries_names) Optional. If not defined, defaults to the target's name.   | String | optional | "" |
| <a id="ninja-lib_source"></a>lib_source |  Label with source code to build. Typically a filegroup for the source of remote repository. Mandatory.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="ninja-linkopts"></a>linkopts |  Optional link options to be passed up to the dependencies of this library   | List of strings | optional | [] |
| <a id="ninja-out_bin_dir"></a>out_bin_dir |  Optional name of the output subdirectory with the binary files, defaults to 'bin'.   | String | optional | "bin" |
| <a id="ninja-out_binaries"></a>out_binaries |  Optional names of the resulting binaries.   | List of strings | optional | [] |
| <a id="ninja-out_headers_only"></a>out_headers_only |  Flag variable to indicate that the library produces only headers   | Boolean | optional | False |
| <a id="ninja-out_include_dir"></a>out_include_dir |  Optional name of the output subdirectory with the header files, defaults to 'include'.   | String | optional | "include" |
| <a id="ninja-out_interface_libs"></a>out_interface_libs |  Optional names of the resulting interface libraries.   | List of strings | optional | [] |
| <a id="ninja-out_lib_dir"></a>out_lib_dir |  Optional name of the output subdirectory with the library files, defaults to 'lib'.   | String | optional | "lib" |
| <a id="ninja-out_shared_libs"></a>out_shared_libs |  Optional names of the resulting shared libraries.   | List of strings | optional | [] |
| <a id="ninja-out_static_libs"></a>out_static_libs |  Optional names of the resulting static libraries. Note that if <code>out_headers_only</code>, <code>out_static_libs</code>, <code>out_shared_libs</code>, and <code>out_binaries</code> are not set, default <code>lib_name.a</code>/<code>lib_name.lib</code> static library is assumed   | List of strings | optional | [] |
| <a id="ninja-postfix_script"></a>postfix_script |  Optional part of the shell script to be added after the make commands   | String | optional | "" |
| <a id="ninja-targets"></a>targets |  A list of targets with in the foreign build system to produce. An empty string (<code>""</code>) will result in a call to the underlying build system with no explicit target set   | List of strings | optional | [] |
| <a id="ninja-tool_prefix"></a>tool_prefix |  A prefix for build commands   | String | optional | "" |
| <a id="ninja-tools_deps"></a>tools_deps |  __deprecated__: Please use the <code>build_data</code> attribute.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |


