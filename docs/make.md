<!-- Generated with Stardoc: http://skydoc.bazel.build -->

A rule for building projects using the [GNU Make](https://www.gnu.org/software/make/) build tool

<a id="#make"></a>

## make

<pre>
make(<a href="#make-name">name</a>, <a href="#make-additional_inputs">additional_inputs</a>, <a href="#make-additional_tools">additional_tools</a>, <a href="#make-alwayslink">alwayslink</a>, <a href="#make-args">args</a>, <a href="#make-build_data">build_data</a>, <a href="#make-data">data</a>, <a href="#make-defines">defines</a>, <a href="#make-deps">deps</a>,
     <a href="#make-env">env</a>, <a href="#make-lib_name">lib_name</a>, <a href="#make-lib_source">lib_source</a>, <a href="#make-linkopts">linkopts</a>, <a href="#make-out_bin_dir">out_bin_dir</a>, <a href="#make-out_binaries">out_binaries</a>, <a href="#make-out_headers_only">out_headers_only</a>,
     <a href="#make-out_include_dir">out_include_dir</a>, <a href="#make-out_interface_libs">out_interface_libs</a>, <a href="#make-out_lib_dir">out_lib_dir</a>, <a href="#make-out_shared_libs">out_shared_libs</a>, <a href="#make-out_static_libs">out_static_libs</a>,
     <a href="#make-postfix_script">postfix_script</a>, <a href="#make-targets">targets</a>, <a href="#make-tool_prefix">tool_prefix</a>, <a href="#make-tools_deps">tools_deps</a>)
</pre>

Rule for building external libraries with GNU Make. GNU Make commands (make and make install by default) are invoked with prefix="install" (by default), and other environment variables for compilation and linking, taken from Bazel C/C++ toolchain and passed dependencies.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="make-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="make-additional_inputs"></a>additional_inputs |  __deprecated__: Please use the <code>build_data</code> attribute.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="make-additional_tools"></a>additional_tools |  __deprecated__: Please use the <code>build_data</code> attribute.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="make-alwayslink"></a>alwayslink |  Optional. if true, link all the object files from the static library, even if they are not used.   | Boolean | optional | False |
| <a id="make-args"></a>args |  A list of arguments to pass to the call to <code>make</code>   | List of strings | optional | [] |
| <a id="make-build_data"></a>build_data |  Files needed by this rule only during build/compile time. May list file or rule targets. Generally allows any target.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="make-data"></a>data |  Files needed by this rule at runtime. May list file or rule targets. Generally allows any target.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="make-defines"></a>defines |  Optional compilation definitions to be passed to the dependencies of this library. They are NOT passed to the compiler, you should duplicate them in the configuration options.   | List of strings | optional | [] |
| <a id="make-deps"></a>deps |  Optional dependencies to be copied into the directory structure. Typically those directly required for the external building of the library/binaries. (i.e. those that the external buidl system will be looking for and paths to which are provided by the calling rule)   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="make-env"></a>env |  Environment variables to set during the build. <code>$(execpath)</code> macros may be used to point at files which are listed as <code>data</code>, <code>deps</code>, or <code>build_data</code>, but unlike with other rules, these will be replaced with absolute paths to those files, because the build does not run in the exec root. No other macros are supported.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="make-lib_name"></a>lib_name |  Library name. Defines the name of the install directory and the name of the static library, if no output files parameters are defined (any of static_libraries, shared_libraries, interface_libraries, binaries_names) Optional. If not defined, defaults to the target's name.   | String | optional | "" |
| <a id="make-lib_source"></a>lib_source |  Label with source code to build. Typically a filegroup for the source of remote repository. Mandatory.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="make-linkopts"></a>linkopts |  Optional link options to be passed up to the dependencies of this library   | List of strings | optional | [] |
| <a id="make-out_bin_dir"></a>out_bin_dir |  Optional name of the output subdirectory with the binary files, defaults to 'bin'.   | String | optional | "bin" |
| <a id="make-out_binaries"></a>out_binaries |  Optional names of the resulting binaries.   | List of strings | optional | [] |
| <a id="make-out_headers_only"></a>out_headers_only |  Flag variable to indicate that the library produces only headers   | Boolean | optional | False |
| <a id="make-out_include_dir"></a>out_include_dir |  Optional name of the output subdirectory with the header files, defaults to 'include'.   | String | optional | "include" |
| <a id="make-out_interface_libs"></a>out_interface_libs |  Optional names of the resulting interface libraries.   | List of strings | optional | [] |
| <a id="make-out_lib_dir"></a>out_lib_dir |  Optional name of the output subdirectory with the library files, defaults to 'lib'.   | String | optional | "lib" |
| <a id="make-out_shared_libs"></a>out_shared_libs |  Optional names of the resulting shared libraries.   | List of strings | optional | [] |
| <a id="make-out_static_libs"></a>out_static_libs |  Optional names of the resulting static libraries. Note that if <code>out_headers_only</code>, <code>out_static_libs</code>, <code>out_shared_libs</code>, and <code>out_binaries</code> are not set, default <code>lib_name.a</code>/<code>lib_name.lib</code> static library is assumed   | List of strings | optional | [] |
| <a id="make-postfix_script"></a>postfix_script |  Optional part of the shell script to be added after the make commands   | String | optional | "" |
| <a id="make-targets"></a>targets |  A list of targets within the foreign build system to produce. An empty string (<code>""</code>) will result in a call to the underlying build system with no explicit target set   | List of strings | optional | ["", "install"] |
| <a id="make-tool_prefix"></a>tool_prefix |  A prefix for build commands   | String | optional | "" |
| <a id="make-tools_deps"></a>tools_deps |  __deprecated__: Please use the <code>build_data</code> attribute.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |


