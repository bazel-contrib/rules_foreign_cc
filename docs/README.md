# Rules Foreign CC

- [boost_build](#boost_build)
- [cmake_external](#cmake_external)
- [cmake_tool](#cmake_tool)
- [ConfigureParameters](#ConfigureParameters)
- [configure_make](#configure_make)
- [ForeignCcArtifact](#ForeignCcArtifact)
- [ForeignCcDeps](#ForeignCcDeps)
- [InputFiles](#InputFiles)
- [make](#make)
- [make_tool](#make_tool)
- [native_tool_toolchain](#native_tool_toolchain)
- [ninja](#ninja)
- [ninja_tool](#ninja_tool)
- [rules_foreign_cc_dependencies](#rules_foreign_cc_dependencies)
- [ToolInfo](#ToolInfo)
- [WrappedOutputs](#WrappedOutputs)

<a id="#boost_build"></a>

## boost_build

<pre>
boost_build(<a href="#boost_build-name">name</a>, <a href="#boost_build-additional_inputs">additional_inputs</a>, <a href="#boost_build-additional_tools">additional_tools</a>, <a href="#boost_build-alwayslink">alwayslink</a>, <a href="#boost_build-binaries">binaries</a>, <a href="#boost_build-bootstrap_options">bootstrap_options</a>,
            <a href="#boost_build-data">data</a>, <a href="#boost_build-defines">defines</a>, <a href="#boost_build-deps">deps</a>, <a href="#boost_build-env">env</a>, <a href="#boost_build-headers_only">headers_only</a>, <a href="#boost_build-interface_libraries">interface_libraries</a>, <a href="#boost_build-lib_name">lib_name</a>, <a href="#boost_build-lib_source">lib_source</a>,
            <a href="#boost_build-linkopts">linkopts</a>, <a href="#boost_build-make_commands">make_commands</a>, <a href="#boost_build-out_bin_dir">out_bin_dir</a>, <a href="#boost_build-out_include_dir">out_include_dir</a>, <a href="#boost_build-out_lib_dir">out_lib_dir</a>, <a href="#boost_build-postfix_script">postfix_script</a>,
            <a href="#boost_build-shared_libraries">shared_libraries</a>, <a href="#boost_build-static_libraries">static_libraries</a>, <a href="#boost_build-tools_deps">tools_deps</a>, <a href="#boost_build-user_options">user_options</a>)
</pre>

Rule for building Boost. Invokes bootstrap.sh and then b2 install.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="boost_build-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="boost_build-additional_inputs"></a>additional_inputs |  Optional additional inputs to be declared as needed for the shell script action.Not used by the shell script part in cc_external_rule_impl.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="boost_build-additional_tools"></a>additional_tools |  Optional additional tools needed for the building. Not used by the shell script part in cc_external_rule_impl.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="boost_build-alwayslink"></a>alwayslink |  Optional. if true, link all the object files from the static library, even if they are not used.   | Boolean | optional | False |
| <a id="boost_build-binaries"></a>binaries |  Optional names of the resulting binaries.   | List of strings | optional | [] |
| <a id="boost_build-bootstrap_options"></a>bootstrap_options |  any additional flags to pass to bootstrap.sh   | List of strings | optional | [] |
| <a id="boost_build-data"></a>data |  Files needed by this rule at runtime. May list file or rule targets. Generally allows any target.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="boost_build-defines"></a>defines |  Optional compilation definitions to be passed to the dependencies of this library. They are NOT passed to the compiler, you should duplicate them in the configuration options.   | List of strings | optional | [] |
| <a id="boost_build-deps"></a>deps |  Optional dependencies to be copied into the directory structure. Typically those directly required for the external building of the library/binaries. (i.e. those that the external buidl system will be looking for and paths to which are provided by the calling rule)   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="boost_build-env"></a>env |  Environment variables to set during the build. $(execpath) macros may be used to point at files which are listed as data deps, tools_deps, or additional_tools, but unlike with other rules, these will be replaced with absolute paths to those files, because the build does not run in the exec root. No other macros are supported.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="boost_build-headers_only"></a>headers_only |  Flag variable to indicate that the library produces only headers   | Boolean | optional | False |
| <a id="boost_build-interface_libraries"></a>interface_libraries |  Optional names of the resulting interface libraries.   | List of strings | optional | [] |
| <a id="boost_build-lib_name"></a>lib_name |  Library name. Defines the name of the install directory and the name of the static library, if no output files parameters are defined (any of static_libraries, shared_libraries, interface_libraries, binaries_names) Optional. If not defined, defaults to the target's name.   | String | optional | "" |
| <a id="boost_build-lib_source"></a>lib_source |  Label with source code to build. Typically a filegroup for the source of remote repository. Mandatory.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="boost_build-linkopts"></a>linkopts |  Optional link options to be passed up to the dependencies of this library   | List of strings | optional | [] |
| <a id="boost_build-make_commands"></a>make_commands |  Optinal make commands, defaults to ["make", "make install"]   | List of strings | optional | ["make", "make install"] |
| <a id="boost_build-out_bin_dir"></a>out_bin_dir |  Optional name of the output subdirectory with the binary files, defaults to 'bin'.   | String | optional | "bin" |
| <a id="boost_build-out_include_dir"></a>out_include_dir |  Optional name of the output subdirectory with the header files, defaults to 'include'.   | String | optional | "include" |
| <a id="boost_build-out_lib_dir"></a>out_lib_dir |  Optional name of the output subdirectory with the library files, defaults to 'lib'.   | String | optional | "lib" |
| <a id="boost_build-postfix_script"></a>postfix_script |  Optional part of the shell script to be added after the make commands   | String | optional | "" |
| <a id="boost_build-shared_libraries"></a>shared_libraries |  Optional names of the resulting shared libraries.   | List of strings | optional | [] |
| <a id="boost_build-static_libraries"></a>static_libraries |  Optional names of the resulting static libraries.   | List of strings | optional | [] |
| <a id="boost_build-tools_deps"></a>tools_deps |  Optional tools to be copied into the directory structure. Similar to deps, those directly required for the external building of the library/binaries.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="boost_build-user_options"></a>user_options |  any additional flags to pass to b2   | List of strings | optional | [] |


<a id="#cmake_external"></a>

## cmake_external

<pre>
cmake_external(<a href="#cmake_external-name">name</a>, <a href="#cmake_external-additional_inputs">additional_inputs</a>, <a href="#cmake_external-additional_tools">additional_tools</a>, <a href="#cmake_external-alwayslink">alwayslink</a>, <a href="#cmake_external-binaries">binaries</a>, <a href="#cmake_external-cache_entries">cache_entries</a>,
               <a href="#cmake_external-cmake_options">cmake_options</a>, <a href="#cmake_external-data">data</a>, <a href="#cmake_external-defines">defines</a>, <a href="#cmake_external-deps">deps</a>, <a href="#cmake_external-env">env</a>, <a href="#cmake_external-env_vars">env_vars</a>, <a href="#cmake_external-generate_crosstool_file">generate_crosstool_file</a>,
               <a href="#cmake_external-headers_only">headers_only</a>, <a href="#cmake_external-install_prefix">install_prefix</a>, <a href="#cmake_external-interface_libraries">interface_libraries</a>, <a href="#cmake_external-lib_name">lib_name</a>, <a href="#cmake_external-lib_source">lib_source</a>, <a href="#cmake_external-linkopts">linkopts</a>,
               <a href="#cmake_external-make_commands">make_commands</a>, <a href="#cmake_external-out_bin_dir">out_bin_dir</a>, <a href="#cmake_external-out_include_dir">out_include_dir</a>, <a href="#cmake_external-out_lib_dir">out_lib_dir</a>, <a href="#cmake_external-postfix_script">postfix_script</a>,
               <a href="#cmake_external-shared_libraries">shared_libraries</a>, <a href="#cmake_external-static_libraries">static_libraries</a>, <a href="#cmake_external-tools_deps">tools_deps</a>, <a href="#cmake_external-working_directory">working_directory</a>)
</pre>

Rule for building external library with CMake.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cmake_external-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="cmake_external-additional_inputs"></a>additional_inputs |  Optional additional inputs to be declared as needed for the shell script action.Not used by the shell script part in cc_external_rule_impl.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="cmake_external-additional_tools"></a>additional_tools |  Optional additional tools needed for the building. Not used by the shell script part in cc_external_rule_impl.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="cmake_external-alwayslink"></a>alwayslink |  Optional. if true, link all the object files from the static library, even if they are not used.   | Boolean | optional | False |
| <a id="cmake_external-binaries"></a>binaries |  Optional names of the resulting binaries.   | List of strings | optional | [] |
| <a id="cmake_external-cache_entries"></a>cache_entries |  CMake cache entries to initialize (they will be passed with -Dkey=value) Values, defined by the toolchain, will be joined with the values, passed here. (Toolchain values come first)   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="cmake_external-cmake_options"></a>cmake_options |  Other CMake options   | List of strings | optional | [] |
| <a id="cmake_external-data"></a>data |  Files needed by this rule at runtime. May list file or rule targets. Generally allows any target.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="cmake_external-defines"></a>defines |  Optional compilation definitions to be passed to the dependencies of this library. They are NOT passed to the compiler, you should duplicate them in the configuration options.   | List of strings | optional | [] |
| <a id="cmake_external-deps"></a>deps |  Optional dependencies to be copied into the directory structure. Typically those directly required for the external building of the library/binaries. (i.e. those that the external buidl system will be looking for and paths to which are provided by the calling rule)   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="cmake_external-env"></a>env |  Environment variables to set during the build. $(execpath) macros may be used to point at files which are listed as data deps, tools_deps, or additional_tools, but unlike with other rules, these will be replaced with absolute paths to those files, because the build does not run in the exec root. No other macros are supported.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="cmake_external-env_vars"></a>env_vars |  CMake environment variable values to join with toolchain-defined. For example, additional CXXFLAGS.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="cmake_external-generate_crosstool_file"></a>generate_crosstool_file |  When True, CMake crosstool file will be generated from the toolchain values, provided cache-entries and env_vars (some values will still be passed as -Dkey=value and environment variables). If CMAKE_TOOLCHAIN_FILE cache entry is passed, specified crosstool file will be used When using this option to cross-compile, it is required to specify CMAKE_SYSTEM_NAME in the cache_entries   | Boolean | optional | True |
| <a id="cmake_external-headers_only"></a>headers_only |  Flag variable to indicate that the library produces only headers   | Boolean | optional | False |
| <a id="cmake_external-install_prefix"></a>install_prefix |  Relative install prefix to be passed to CMake in -DCMAKE_INSTALL_PREFIX   | String | optional | "" |
| <a id="cmake_external-interface_libraries"></a>interface_libraries |  Optional names of the resulting interface libraries.   | List of strings | optional | [] |
| <a id="cmake_external-lib_name"></a>lib_name |  Library name. Defines the name of the install directory and the name of the static library, if no output files parameters are defined (any of static_libraries, shared_libraries, interface_libraries, binaries_names) Optional. If not defined, defaults to the target's name.   | String | optional | "" |
| <a id="cmake_external-lib_source"></a>lib_source |  Label with source code to build. Typically a filegroup for the source of remote repository. Mandatory.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="cmake_external-linkopts"></a>linkopts |  Optional link options to be passed up to the dependencies of this library   | List of strings | optional | [] |
| <a id="cmake_external-make_commands"></a>make_commands |  Optinal make commands, defaults to ["make", "make install"]   | List of strings | optional | ["make", "make install"] |
| <a id="cmake_external-out_bin_dir"></a>out_bin_dir |  Optional name of the output subdirectory with the binary files, defaults to 'bin'.   | String | optional | "bin" |
| <a id="cmake_external-out_include_dir"></a>out_include_dir |  Optional name of the output subdirectory with the header files, defaults to 'include'.   | String | optional | "include" |
| <a id="cmake_external-out_lib_dir"></a>out_lib_dir |  Optional name of the output subdirectory with the library files, defaults to 'lib'.   | String | optional | "lib" |
| <a id="cmake_external-postfix_script"></a>postfix_script |  Optional part of the shell script to be added after the make commands   | String | optional | "" |
| <a id="cmake_external-shared_libraries"></a>shared_libraries |  Optional names of the resulting shared libraries.   | List of strings | optional | [] |
| <a id="cmake_external-static_libraries"></a>static_libraries |  Optional names of the resulting static libraries.   | List of strings | optional | [] |
| <a id="cmake_external-tools_deps"></a>tools_deps |  Optional tools to be copied into the directory structure. Similar to deps, those directly required for the external building of the library/binaries.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="cmake_external-working_directory"></a>working_directory |  Working directory, with the main CMakeLists.txt (otherwise, the top directory of the lib_source label files is used.)   | String | optional | "" |


<a id="#cmake_tool"></a>

## cmake_tool

<pre>
cmake_tool(<a href="#cmake_tool-name">name</a>, <a href="#cmake_tool-cmake_srcs">cmake_srcs</a>)
</pre>

Rule for building CMake. Invokes bootstrap script and make install.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cmake_tool-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="cmake_tool-cmake_srcs"></a>cmake_srcs |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#configure_make"></a>

## configure_make

<pre>
configure_make(<a href="#configure_make-name">name</a>, <a href="#configure_make-additional_inputs">additional_inputs</a>, <a href="#configure_make-additional_tools">additional_tools</a>, <a href="#configure_make-alwayslink">alwayslink</a>, <a href="#configure_make-autoconf">autoconf</a>, <a href="#configure_make-autoconf_env_vars">autoconf_env_vars</a>,
               <a href="#configure_make-autoconf_options">autoconf_options</a>, <a href="#configure_make-autogen">autogen</a>, <a href="#configure_make-autogen_command">autogen_command</a>, <a href="#configure_make-autogen_env_vars">autogen_env_vars</a>, <a href="#configure_make-autogen_options">autogen_options</a>,
               <a href="#configure_make-autoreconf">autoreconf</a>, <a href="#configure_make-autoreconf_env_vars">autoreconf_env_vars</a>, <a href="#configure_make-autoreconf_options">autoreconf_options</a>, <a href="#configure_make-binaries">binaries</a>, <a href="#configure_make-configure_command">configure_command</a>,
               <a href="#configure_make-configure_env_vars">configure_env_vars</a>, <a href="#configure_make-configure_in_place">configure_in_place</a>, <a href="#configure_make-configure_options">configure_options</a>, <a href="#configure_make-data">data</a>, <a href="#configure_make-defines">defines</a>, <a href="#configure_make-deps">deps</a>, <a href="#configure_make-env">env</a>,
               <a href="#configure_make-headers_only">headers_only</a>, <a href="#configure_make-install_prefix">install_prefix</a>, <a href="#configure_make-interface_libraries">interface_libraries</a>, <a href="#configure_make-lib_name">lib_name</a>, <a href="#configure_make-lib_source">lib_source</a>, <a href="#configure_make-linkopts">linkopts</a>,
               <a href="#configure_make-make_commands">make_commands</a>, <a href="#configure_make-out_bin_dir">out_bin_dir</a>, <a href="#configure_make-out_include_dir">out_include_dir</a>, <a href="#configure_make-out_lib_dir">out_lib_dir</a>, <a href="#configure_make-postfix_script">postfix_script</a>,
               <a href="#configure_make-shared_libraries">shared_libraries</a>, <a href="#configure_make-static_libraries">static_libraries</a>, <a href="#configure_make-tools_deps">tools_deps</a>)
</pre>

Rule for building external libraries with configure-make pattern. Some 'configure' script is invoked with --prefix=install (by default), and other parameters for compilation and linking, taken from Bazel C/C++ toolchain and passed dependencies. After configuration, GNU Make is called.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="configure_make-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="configure_make-additional_inputs"></a>additional_inputs |  Optional additional inputs to be declared as needed for the shell script action.Not used by the shell script part in cc_external_rule_impl.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="configure_make-additional_tools"></a>additional_tools |  Optional additional tools needed for the building. Not used by the shell script part in cc_external_rule_impl.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="configure_make-alwayslink"></a>alwayslink |  Optional. if true, link all the object files from the static library, even if they are not used.   | Boolean | optional | False |
| <a id="configure_make-autoconf"></a>autoconf |  Set to True if 'autoconf' should be invoked before 'configure', currently requires 'configure_in_place' to be True.   | Boolean | optional | False |
| <a id="configure_make-autoconf_env_vars"></a>autoconf_env_vars |  Environment variables to be set for 'autoconf' invocation.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="configure_make-autoconf_options"></a>autoconf_options |  Any options to be put in the 'autoconf.sh' command line.   | List of strings | optional | [] |
| <a id="configure_make-autogen"></a>autogen |  Set to True if 'autogen.sh' should be invoked before 'configure', currently requires 'configure_in_place' to be True.   | Boolean | optional | False |
| <a id="configure_make-autogen_command"></a>autogen_command |  The name of the autogen script file, default: autogen.sh. Many projects use autogen.sh however the Autotools FAQ recommends bootstrap so we provide this option to support that.   | String | optional | "autogen.sh" |
| <a id="configure_make-autogen_env_vars"></a>autogen_env_vars |  Environment variables to be set for 'autogen' invocation.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="configure_make-autogen_options"></a>autogen_options |  Any options to be put in the 'autogen.sh' command line.   | List of strings | optional | [] |
| <a id="configure_make-autoreconf"></a>autoreconf |  Set to True if 'autoreconf' should be invoked before 'configure.', currently requires 'configure_in_place' to be True.   | Boolean | optional | False |
| <a id="configure_make-autoreconf_env_vars"></a>autoreconf_env_vars |  Environment variables to be set for 'autoreconf' invocation.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="configure_make-autoreconf_options"></a>autoreconf_options |  Any options to be put in the 'autoreconf.sh' command line.   | List of strings | optional | [] |
| <a id="configure_make-binaries"></a>binaries |  Optional names of the resulting binaries.   | List of strings | optional | [] |
| <a id="configure_make-configure_command"></a>configure_command |  The name of the configuration script file, default: configure. The file must be in the root of the source directory.   | String | optional | "configure" |
| <a id="configure_make-configure_env_vars"></a>configure_env_vars |  Environment variables to be set for the 'configure' invocation.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="configure_make-configure_in_place"></a>configure_in_place |  Set to True if 'configure' should be invoked in place, i.e. from its enclosing directory.   | Boolean | optional | False |
| <a id="configure_make-configure_options"></a>configure_options |  Any options to be put on the 'configure' command line.   | List of strings | optional | [] |
| <a id="configure_make-data"></a>data |  Files needed by this rule at runtime. May list file or rule targets. Generally allows any target.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="configure_make-defines"></a>defines |  Optional compilation definitions to be passed to the dependencies of this library. They are NOT passed to the compiler, you should duplicate them in the configuration options.   | List of strings | optional | [] |
| <a id="configure_make-deps"></a>deps |  Optional dependencies to be copied into the directory structure. Typically those directly required for the external building of the library/binaries. (i.e. those that the external buidl system will be looking for and paths to which are provided by the calling rule)   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="configure_make-env"></a>env |  Environment variables to set during the build. $(execpath) macros may be used to point at files which are listed as data deps, tools_deps, or additional_tools, but unlike with other rules, these will be replaced with absolute paths to those files, because the build does not run in the exec root. No other macros are supported.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="configure_make-headers_only"></a>headers_only |  Flag variable to indicate that the library produces only headers   | Boolean | optional | False |
| <a id="configure_make-install_prefix"></a>install_prefix |  Install prefix, i.e. relative path to where to install the result of the build. Passed to the 'configure' script with --prefix flag.   | String | optional | "" |
| <a id="configure_make-interface_libraries"></a>interface_libraries |  Optional names of the resulting interface libraries.   | List of strings | optional | [] |
| <a id="configure_make-lib_name"></a>lib_name |  Library name. Defines the name of the install directory and the name of the static library, if no output files parameters are defined (any of static_libraries, shared_libraries, interface_libraries, binaries_names) Optional. If not defined, defaults to the target's name.   | String | optional | "" |
| <a id="configure_make-lib_source"></a>lib_source |  Label with source code to build. Typically a filegroup for the source of remote repository. Mandatory.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="configure_make-linkopts"></a>linkopts |  Optional link options to be passed up to the dependencies of this library   | List of strings | optional | [] |
| <a id="configure_make-make_commands"></a>make_commands |  Optinal make commands, defaults to ["make", "make install"]   | List of strings | optional | ["make", "make install"] |
| <a id="configure_make-out_bin_dir"></a>out_bin_dir |  Optional name of the output subdirectory with the binary files, defaults to 'bin'.   | String | optional | "bin" |
| <a id="configure_make-out_include_dir"></a>out_include_dir |  Optional name of the output subdirectory with the header files, defaults to 'include'.   | String | optional | "include" |
| <a id="configure_make-out_lib_dir"></a>out_lib_dir |  Optional name of the output subdirectory with the library files, defaults to 'lib'.   | String | optional | "lib" |
| <a id="configure_make-postfix_script"></a>postfix_script |  Optional part of the shell script to be added after the make commands   | String | optional | "" |
| <a id="configure_make-shared_libraries"></a>shared_libraries |  Optional names of the resulting shared libraries.   | List of strings | optional | [] |
| <a id="configure_make-static_libraries"></a>static_libraries |  Optional names of the resulting static libraries.   | List of strings | optional | [] |
| <a id="configure_make-tools_deps"></a>tools_deps |  Optional tools to be copied into the directory structure. Similar to deps, those directly required for the external building of the library/binaries.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |


<a id="#make"></a>

## make

<pre>
make(<a href="#make-name">name</a>, <a href="#make-additional_inputs">additional_inputs</a>, <a href="#make-additional_tools">additional_tools</a>, <a href="#make-alwayslink">alwayslink</a>, <a href="#make-binaries">binaries</a>, <a href="#make-data">data</a>, <a href="#make-defines">defines</a>, <a href="#make-deps">deps</a>, <a href="#make-env">env</a>,
     <a href="#make-headers_only">headers_only</a>, <a href="#make-interface_libraries">interface_libraries</a>, <a href="#make-keep_going">keep_going</a>, <a href="#make-lib_name">lib_name</a>, <a href="#make-lib_source">lib_source</a>, <a href="#make-linkopts">linkopts</a>, <a href="#make-make_commands">make_commands</a>,
     <a href="#make-make_env_vars">make_env_vars</a>, <a href="#make-out_bin_dir">out_bin_dir</a>, <a href="#make-out_include_dir">out_include_dir</a>, <a href="#make-out_lib_dir">out_lib_dir</a>, <a href="#make-postfix_script">postfix_script</a>, <a href="#make-prefix">prefix</a>,
     <a href="#make-shared_libraries">shared_libraries</a>, <a href="#make-static_libraries">static_libraries</a>, <a href="#make-tools_deps">tools_deps</a>)
</pre>

Rule for building external libraries with GNU Make. GNU Make commands (make and make install by default) are invoked with prefix="install" (by default), and other environment variables for compilation and linking, taken from Bazel C/C++ toolchain and passed dependencies.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="make-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="make-additional_inputs"></a>additional_inputs |  Optional additional inputs to be declared as needed for the shell script action.Not used by the shell script part in cc_external_rule_impl.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="make-additional_tools"></a>additional_tools |  Optional additional tools needed for the building. Not used by the shell script part in cc_external_rule_impl.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="make-alwayslink"></a>alwayslink |  Optional. if true, link all the object files from the static library, even if they are not used.   | Boolean | optional | False |
| <a id="make-binaries"></a>binaries |  Optional names of the resulting binaries.   | List of strings | optional | [] |
| <a id="make-data"></a>data |  Files needed by this rule at runtime. May list file or rule targets. Generally allows any target.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="make-defines"></a>defines |  Optional compilation definitions to be passed to the dependencies of this library. They are NOT passed to the compiler, you should duplicate them in the configuration options.   | List of strings | optional | [] |
| <a id="make-deps"></a>deps |  Optional dependencies to be copied into the directory structure. Typically those directly required for the external building of the library/binaries. (i.e. those that the external buidl system will be looking for and paths to which are provided by the calling rule)   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="make-env"></a>env |  Environment variables to set during the build. $(execpath) macros may be used to point at files which are listed as data deps, tools_deps, or additional_tools, but unlike with other rules, these will be replaced with absolute paths to those files, because the build does not run in the exec root. No other macros are supported.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="make-headers_only"></a>headers_only |  Flag variable to indicate that the library produces only headers   | Boolean | optional | False |
| <a id="make-interface_libraries"></a>interface_libraries |  Optional names of the resulting interface libraries.   | List of strings | optional | [] |
| <a id="make-keep_going"></a>keep_going |  Keep going when some targets can not be made, -k flag is passed to make (applies only if make_commands attribute is not set). Please have a look at _create_make_script for default make_commands.   | Boolean | optional | True |
| <a id="make-lib_name"></a>lib_name |  Library name. Defines the name of the install directory and the name of the static library, if no output files parameters are defined (any of static_libraries, shared_libraries, interface_libraries, binaries_names) Optional. If not defined, defaults to the target's name.   | String | optional | "" |
| <a id="make-lib_source"></a>lib_source |  Label with source code to build. Typically a filegroup for the source of remote repository. Mandatory.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="make-linkopts"></a>linkopts |  Optional link options to be passed up to the dependencies of this library   | List of strings | optional | [] |
| <a id="make-make_commands"></a>make_commands |  Overriding make_commands default value to be empty, then we can provide better default value programmatically   | List of strings | optional | [] |
| <a id="make-make_env_vars"></a>make_env_vars |  Environment variables to be set for the 'configure' invocation.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="make-out_bin_dir"></a>out_bin_dir |  Optional name of the output subdirectory with the binary files, defaults to 'bin'.   | String | optional | "bin" |
| <a id="make-out_include_dir"></a>out_include_dir |  Optional name of the output subdirectory with the header files, defaults to 'include'.   | String | optional | "include" |
| <a id="make-out_lib_dir"></a>out_lib_dir |  Optional name of the output subdirectory with the library files, defaults to 'lib'.   | String | optional | "lib" |
| <a id="make-postfix_script"></a>postfix_script |  Optional part of the shell script to be added after the make commands   | String | optional | "" |
| <a id="make-prefix"></a>prefix |  Install prefix, an absolute path. Passed to the GNU make via "make install PREFIX=&lt;value&gt;". By default, the install directory created under sandboxed execution root is used. Build results are copied to the Bazel's output directory, so the prefix is only important if it is recorded into any text files by Makefile script. In that case, it is important to note that rules_foreign_cc is overriding the paths under execution root with "BAZEL_GEN_ROOT" value.   | String | optional | "" |
| <a id="make-shared_libraries"></a>shared_libraries |  Optional names of the resulting shared libraries.   | List of strings | optional | [] |
| <a id="make-static_libraries"></a>static_libraries |  Optional names of the resulting static libraries.   | List of strings | optional | [] |
| <a id="make-tools_deps"></a>tools_deps |  Optional tools to be copied into the directory structure. Similar to deps, those directly required for the external building of the library/binaries.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |


<a id="#make_tool"></a>

## make_tool

<pre>
make_tool(<a href="#make_tool-name">name</a>, <a href="#make_tool-make_srcs">make_srcs</a>)
</pre>

Rule for building Make. Invokes configure script and make install.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="make_tool-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="make_tool-make_srcs"></a>make_srcs |  target with the Make sources   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#native_tool_toolchain"></a>

## native_tool_toolchain

<pre>
native_tool_toolchain(<a href="#native_tool_toolchain-name">name</a>, <a href="#native_tool_toolchain-path">path</a>, <a href="#native_tool_toolchain-target">target</a>)
</pre>

Rule for defining the toolchain data of the native tools (cmake, ninja), to be used by rules_foreign_cc with toolchain types `@rules_foreign_cc//tools/build_defs:cmake_toolchain` and `@rules_foreign_cc//tools/build_defs:ninja_toolchain`.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="native_tool_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="native_tool_toolchain-path"></a>path |  Absolute path to the tool in case the tool is preinstalled on the machine. Relative path to the tool in case the tool is built as part of a build; the path should be relative to the bazel-genfiles, i.e. it should start with the name of the top directory of the built tree artifact. (Please see the example <code>//examples:built_cmake_toolchain</code>)   | String | optional | "" |
| <a id="native_tool_toolchain-target"></a>target |  If the tool is preinstalled, must be None. If the tool is built as part of the build, the corresponding build target, which should produce the tree artifact with the binary to call.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#ninja"></a>

## ninja

<pre>
ninja(<a href="#ninja-name">name</a>, <a href="#ninja-additional_inputs">additional_inputs</a>, <a href="#ninja-additional_tools">additional_tools</a>, <a href="#ninja-alwayslink">alwayslink</a>, <a href="#ninja-args">args</a>, <a href="#ninja-binaries">binaries</a>, <a href="#ninja-data">data</a>, <a href="#ninja-defines">defines</a>, <a href="#ninja-deps">deps</a>,
      <a href="#ninja-directory">directory</a>, <a href="#ninja-env">env</a>, <a href="#ninja-headers_only">headers_only</a>, <a href="#ninja-interface_libraries">interface_libraries</a>, <a href="#ninja-lib_name">lib_name</a>, <a href="#ninja-lib_source">lib_source</a>, <a href="#ninja-linkopts">linkopts</a>, <a href="#ninja-out_bin_dir">out_bin_dir</a>,
      <a href="#ninja-out_include_dir">out_include_dir</a>, <a href="#ninja-out_lib_dir">out_lib_dir</a>, <a href="#ninja-postfix_script">postfix_script</a>, <a href="#ninja-shared_libraries">shared_libraries</a>, <a href="#ninja-static_libraries">static_libraries</a>, <a href="#ninja-targets">targets</a>,
      <a href="#ninja-tools_deps">tools_deps</a>)
</pre>

Rule for building external libraries with [Ninja](https://ninja-build.org/).

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="ninja-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="ninja-additional_inputs"></a>additional_inputs |  Optional additional inputs to be declared as needed for the shell script action.Not used by the shell script part in cc_external_rule_impl.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="ninja-additional_tools"></a>additional_tools |  Optional additional tools needed for the building. Not used by the shell script part in cc_external_rule_impl.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="ninja-alwayslink"></a>alwayslink |  Optional. if true, link all the object files from the static library, even if they are not used.   | Boolean | optional | False |
| <a id="ninja-args"></a>args |  A list of arguments to pass to the call to <code>ninja</code>   | List of strings | optional | [] |
| <a id="ninja-binaries"></a>binaries |  Optional names of the resulting binaries.   | List of strings | optional | [] |
| <a id="ninja-data"></a>data |  Files needed by this rule at runtime. May list file or rule targets. Generally allows any target.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="ninja-defines"></a>defines |  Optional compilation definitions to be passed to the dependencies of this library. They are NOT passed to the compiler, you should duplicate them in the configuration options.   | List of strings | optional | [] |
| <a id="ninja-deps"></a>deps |  Optional dependencies to be copied into the directory structure. Typically those directly required for the external building of the library/binaries. (i.e. those that the external buidl system will be looking for and paths to which are provided by the calling rule)   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="ninja-directory"></a>directory |  A directory to pass as the <code>-C</code> argument. The rule will always use the root directory of the <code>lib_sources</code> attribute if this attribute is not set   | String | optional | "" |
| <a id="ninja-env"></a>env |  Environment variables to set during the build. $(execpath) macros may be used to point at files which are listed as data deps, tools_deps, or additional_tools, but unlike with other rules, these will be replaced with absolute paths to those files, because the build does not run in the exec root. No other macros are supported.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="ninja-headers_only"></a>headers_only |  Flag variable to indicate that the library produces only headers   | Boolean | optional | False |
| <a id="ninja-interface_libraries"></a>interface_libraries |  Optional names of the resulting interface libraries.   | List of strings | optional | [] |
| <a id="ninja-lib_name"></a>lib_name |  Library name. Defines the name of the install directory and the name of the static library, if no output files parameters are defined (any of static_libraries, shared_libraries, interface_libraries, binaries_names) Optional. If not defined, defaults to the target's name.   | String | optional | "" |
| <a id="ninja-lib_source"></a>lib_source |  Label with source code to build. Typically a filegroup for the source of remote repository. Mandatory.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="ninja-linkopts"></a>linkopts |  Optional link options to be passed up to the dependencies of this library   | List of strings | optional | [] |
| <a id="ninja-out_bin_dir"></a>out_bin_dir |  Optional name of the output subdirectory with the binary files, defaults to 'bin'.   | String | optional | "bin" |
| <a id="ninja-out_include_dir"></a>out_include_dir |  Optional name of the output subdirectory with the header files, defaults to 'include'.   | String | optional | "include" |
| <a id="ninja-out_lib_dir"></a>out_lib_dir |  Optional name of the output subdirectory with the library files, defaults to 'lib'.   | String | optional | "lib" |
| <a id="ninja-postfix_script"></a>postfix_script |  Optional part of the shell script to be added after the make commands   | String | optional | "" |
| <a id="ninja-shared_libraries"></a>shared_libraries |  Optional names of the resulting shared libraries.   | List of strings | optional | [] |
| <a id="ninja-static_libraries"></a>static_libraries |  Optional names of the resulting static libraries.   | List of strings | optional | [] |
| <a id="ninja-targets"></a>targets |  A list of ninja targets to build. To call the default target, simply pass <code>""</code> as one of the items to this attribute.   | List of strings | optional | [] |
| <a id="ninja-tools_deps"></a>tools_deps |  Optional tools to be copied into the directory structure. Similar to deps, those directly required for the external building of the library/binaries.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |


<a id="#ninja_tool"></a>

## ninja_tool

<pre>
ninja_tool(<a href="#ninja_tool-name">name</a>, <a href="#ninja_tool-ninja_srcs">ninja_srcs</a>)
</pre>

Rule for building Ninja. Invokes configure script and make install.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="ninja_tool-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="ninja_tool-ninja_srcs"></a>ninja_srcs |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#ConfigureParameters"></a>

## ConfigureParameters

<pre>
ConfigureParameters(<a href="#ConfigureParameters-ctx">ctx</a>, <a href="#ConfigureParameters-attrs">attrs</a>, <a href="#ConfigureParameters-inputs">inputs</a>)
</pre>

Parameters of create_configure_script callback function, called by
cc_external_rule_impl function. create_configure_script creates the configuration part
of the script, and allows to reuse the inputs structure, created by the framework.

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="ConfigureParameters-ctx"></a>ctx |  Rule context    |
| <a id="ConfigureParameters-attrs"></a>attrs |  Attributes struct, created by create_attrs function above    |
| <a id="ConfigureParameters-inputs"></a>inputs |  InputFiles provider: summarized information on rule inputs, created by framework function, to be reused in script creator. Contains in particular merged compilation and linking dependencies.    |


<a id="#ForeignCcArtifact"></a>

## ForeignCcArtifact

<pre>
ForeignCcArtifact(<a href="#ForeignCcArtifact-bin_dir_name">bin_dir_name</a>, <a href="#ForeignCcArtifact-gen_dir">gen_dir</a>, <a href="#ForeignCcArtifact-include_dir_name">include_dir_name</a>, <a href="#ForeignCcArtifact-lib_dir_name">lib_dir_name</a>)
</pre>

Groups information about the external library install directory,
and relative bin, include and lib directories.

Serves to pass transitive information about externally built artifacts up the dependency chain.

Can not be used as a top-level provider.
Instances of ForeignCcArtifact are incapsulated in a depset ForeignCcDeps#artifacts.

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="ForeignCcArtifact-bin_dir_name"></a>bin_dir_name |  Bin directory, relative to install directory    |
| <a id="ForeignCcArtifact-gen_dir"></a>gen_dir |  Install directory    |
| <a id="ForeignCcArtifact-include_dir_name"></a>include_dir_name |  Include directory, relative to install directory    |
| <a id="ForeignCcArtifact-lib_dir_name"></a>lib_dir_name |  Lib directory, relative to install directory    |


<a id="#ForeignCcDeps"></a>

## ForeignCcDeps

<pre>
ForeignCcDeps(<a href="#ForeignCcDeps-artifacts">artifacts</a>)
</pre>

Provider to pass transitive information about external libraries.

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="ForeignCcDeps-artifacts"></a>artifacts |  Depset of ForeignCcArtifact    |


<a id="#InputFiles"></a>

## InputFiles

<pre>
InputFiles(<a href="#InputFiles-headers">headers</a>, <a href="#InputFiles-include_dirs">include_dirs</a>, <a href="#InputFiles-libs">libs</a>, <a href="#InputFiles-tools_files">tools_files</a>, <a href="#InputFiles-ext_build_dirs">ext_build_dirs</a>, <a href="#InputFiles-deps_compilation_info">deps_compilation_info</a>,
           <a href="#InputFiles-deps_linking_info">deps_linking_info</a>, <a href="#InputFiles-declared_inputs">declared_inputs</a>)
</pre>

Provider to keep different kinds of input files, directories, and C/C++ compilation and linking info from dependencies

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="InputFiles-headers"></a>headers |  Include files built by Bazel. Will be copied into $EXT_BUILD_DEPS/include.    |
| <a id="InputFiles-include_dirs"></a>include_dirs |  Include directories built by Bazel. Will be copied into $EXT_BUILD_DEPS/include.    |
| <a id="InputFiles-libs"></a>libs |  Library files built by Bazel. Will be copied into $EXT_BUILD_DEPS/lib.    |
| <a id="InputFiles-tools_files"></a>tools_files |  Files and directories with tools needed for configuration/building to be copied into the bin folder, which is added to the PATH    |
| <a id="InputFiles-ext_build_dirs"></a>ext_build_dirs |  Directories with libraries, built by framework function. This directories should be copied into $EXT_BUILD_DEPS/lib-name as is, with all contents.    |
| <a id="InputFiles-deps_compilation_info"></a>deps_compilation_info |  Merged CcCompilationInfo from deps attribute    |
| <a id="InputFiles-deps_linking_info"></a>deps_linking_info |  Merged CcLinkingInfo from deps attribute    |
| <a id="InputFiles-declared_inputs"></a>declared_inputs |  All files and directories that must be declared as action inputs    |


<a id="#ToolInfo"></a>

## ToolInfo

<pre>
ToolInfo(<a href="#ToolInfo-path">path</a>, <a href="#ToolInfo-target">target</a>)
</pre>

Information about the native tool

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="ToolInfo-path"></a>path |  Absolute path to the tool in case the tool is preinstalled on the machine. Relative path to the tool in case the tool is built as part of a build; the path should be relative to the bazel-genfiles, i.e. it should start with the name of the top directory of the built tree artifact. (Please see the example <code>//examples:built_cmake_toolchain</code>)    |
| <a id="ToolInfo-target"></a>target |  If the tool is preinstalled, must be None. If the tool is built as part of the build, the corresponding build target, which should produce the tree artifact with the binary to call.    |


<a id="#WrappedOutputs"></a>

## WrappedOutputs

<pre>
WrappedOutputs(<a href="#WrappedOutputs-log_file">log_file</a>, <a href="#WrappedOutputs-script_file">script_file</a>, <a href="#WrappedOutputs-wrapper_script">wrapper_script</a>, <a href="#WrappedOutputs-wrapper_script_file">wrapper_script_file</a>)
</pre>

Structure for passing the log and scripts file information, and wrapper script text.

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="WrappedOutputs-log_file"></a>log_file |  Execution log file    |
| <a id="WrappedOutputs-script_file"></a>script_file |  Main script file    |
| <a id="WrappedOutputs-wrapper_script"></a>wrapper_script |  Wrapper script text to execute    |
| <a id="WrappedOutputs-wrapper_script_file"></a>wrapper_script_file |  Wrapper script file (output for debugging purposes)    |


<a id="#rules_foreign_cc_dependencies"></a>

## rules_foreign_cc_dependencies

<pre>
rules_foreign_cc_dependencies(<a href="#rules_foreign_cc_dependencies-native_tools_toolchains">native_tools_toolchains</a>, <a href="#rules_foreign_cc_dependencies-register_default_tools">register_default_tools</a>, <a href="#rules_foreign_cc_dependencies-cmake_version">cmake_version</a>,
                              <a href="#rules_foreign_cc_dependencies-ninja_version">ninja_version</a>, <a href="#rules_foreign_cc_dependencies-register_preinstalled_tools">register_preinstalled_tools</a>, <a href="#rules_foreign_cc_dependencies-register_built_tools">register_built_tools</a>,
                              <a href="#rules_foreign_cc_dependencies-additional_shell_toolchain_mappings">additional_shell_toolchain_mappings</a>, <a href="#rules_foreign_cc_dependencies-additional_shell_toolchain_package">additional_shell_toolchain_package</a>)
</pre>

Call this function from the WORKSPACE file to initialize rules_foreign_cc     dependencies and let neccesary code generation happen     (Code generation is needed to support different variants of the C++ Starlark API.).

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="rules_foreign_cc_dependencies-native_tools_toolchains"></a>native_tools_toolchains |  pass the toolchains for toolchain types     '@rules_foreign_cc//tools/build_defs:cmake_toolchain' and     '@rules_foreign_cc//tools/build_defs:ninja_toolchain' with the needed platform constraints.     If you do not pass anything, registered default toolchains will be selected (see below).   |  <code>[]</code> |
| <a id="rules_foreign_cc_dependencies-register_default_tools"></a>register_default_tools |  If True, the cmake and ninja toolchains, calling corresponding     preinstalled binaries by name (cmake, ninja) will be registered after     'native_tools_toolchains' without any platform constraints. The default is True.   |  <code>True</code> |
| <a id="rules_foreign_cc_dependencies-cmake_version"></a>cmake_version |  The target version of the default cmake toolchain if <code>register_default_tools</code>     is set to <code>True</code>.   |  <code>"3.19.6"</code> |
| <a id="rules_foreign_cc_dependencies-ninja_version"></a>ninja_version |  The target version of the default ninja toolchain if <code>register_default_tools</code>     is set to <code>True</code>.   |  <code>"1.10.2"</code> |
| <a id="rules_foreign_cc_dependencies-register_preinstalled_tools"></a>register_preinstalled_tools |  If true, toolchains will be registered for the native built tools     installed on the exec host   |  <code>True</code> |
| <a id="rules_foreign_cc_dependencies-register_built_tools"></a>register_built_tools |  If true, toolchains that build the tools from source are registered   |  <code>True</code> |
| <a id="rules_foreign_cc_dependencies-additional_shell_toolchain_mappings"></a>additional_shell_toolchain_mappings |  Mappings of the shell toolchain functions to     execution and target platforms constraints. Similar to what defined in     @rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:toolchain_mappings.bzl     in the TOOLCHAIN_MAPPINGS list. Please refer to example in @rules_foreign_cc//toolchain_examples.   |  <code>[]</code> |
| <a id="rules_foreign_cc_dependencies-additional_shell_toolchain_package"></a>additional_shell_toolchain_package |  A package under which additional toolchains, referencing     the generated data for the passed additonal_shell_toolchain_mappings, will be defined.     This value is needed since register_toolchains() is called for these toolchains.     Please refer to example in @rules_foreign_cc//toolchain_examples.   |  <code>None</code> |


