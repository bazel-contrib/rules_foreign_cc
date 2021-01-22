<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a id="#boost_build"></a>

## boost_build

<pre>
boost_build(<a href="#boost_build-name">name</a>, <a href="#boost_build-additional_inputs">additional_inputs</a>, <a href="#boost_build-additional_tools">additional_tools</a>, <a href="#boost_build-alwayslink">alwayslink</a>, <a href="#boost_build-binaries">binaries</a>, <a href="#boost_build-bootstrap_options">bootstrap_options</a>,
            <a href="#boost_build-defines">defines</a>, <a href="#boost_build-deps">deps</a>, <a href="#boost_build-headers_only">headers_only</a>, <a href="#boost_build-interface_libraries">interface_libraries</a>, <a href="#boost_build-lib_name">lib_name</a>, <a href="#boost_build-lib_source">lib_source</a>, <a href="#boost_build-linkopts">linkopts</a>,
            <a href="#boost_build-make_commands">make_commands</a>, <a href="#boost_build-out_bin_dir">out_bin_dir</a>, <a href="#boost_build-out_include_dir">out_include_dir</a>, <a href="#boost_build-out_lib_dir">out_lib_dir</a>, <a href="#boost_build-postfix_script">postfix_script</a>,
            <a href="#boost_build-shared_libraries">shared_libraries</a>, <a href="#boost_build-static_libraries">static_libraries</a>, <a href="#boost_build-tools_deps">tools_deps</a>, <a href="#boost_build-user_options">user_options</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="boost_build-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="boost_build-additional_inputs"></a>additional_inputs |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="boost_build-additional_tools"></a>additional_tools |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="boost_build-alwayslink"></a>alwayslink |  -   | Boolean | optional | False |
| <a id="boost_build-binaries"></a>binaries |  -   | List of strings | optional | [] |
| <a id="boost_build-bootstrap_options"></a>bootstrap_options |  -   | List of strings | optional | [] |
| <a id="boost_build-defines"></a>defines |  -   | List of strings | optional | [] |
| <a id="boost_build-deps"></a>deps |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="boost_build-headers_only"></a>headers_only |  -   | Boolean | optional | False |
| <a id="boost_build-interface_libraries"></a>interface_libraries |  -   | List of strings | optional | [] |
| <a id="boost_build-lib_name"></a>lib_name |  -   | String | optional | "" |
| <a id="boost_build-lib_source"></a>lib_source |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="boost_build-linkopts"></a>linkopts |  -   | List of strings | optional | [] |
| <a id="boost_build-make_commands"></a>make_commands |  -   | List of strings | optional | ["make", "make install"] |
| <a id="boost_build-out_bin_dir"></a>out_bin_dir |  -   | String | optional | "bin" |
| <a id="boost_build-out_include_dir"></a>out_include_dir |  -   | String | optional | "include" |
| <a id="boost_build-out_lib_dir"></a>out_lib_dir |  -   | String | optional | "lib" |
| <a id="boost_build-postfix_script"></a>postfix_script |  -   | String | optional | "" |
| <a id="boost_build-shared_libraries"></a>shared_libraries |  -   | List of strings | optional | [] |
| <a id="boost_build-static_libraries"></a>static_libraries |  -   | List of strings | optional | [] |
| <a id="boost_build-tools_deps"></a>tools_deps |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="boost_build-user_options"></a>user_options |  -   | List of strings | optional | [] |


<a id="#cmake_external"></a>

## cmake_external

<pre>
cmake_external(<a href="#cmake_external-name">name</a>, <a href="#cmake_external-additional_inputs">additional_inputs</a>, <a href="#cmake_external-additional_tools">additional_tools</a>, <a href="#cmake_external-alwayslink">alwayslink</a>, <a href="#cmake_external-binaries">binaries</a>, <a href="#cmake_external-cache_entries">cache_entries</a>,
               <a href="#cmake_external-cmake_options">cmake_options</a>, <a href="#cmake_external-defines">defines</a>, <a href="#cmake_external-deps">deps</a>, <a href="#cmake_external-env_vars">env_vars</a>, <a href="#cmake_external-generate_crosstool_file">generate_crosstool_file</a>, <a href="#cmake_external-headers_only">headers_only</a>,
               <a href="#cmake_external-install_prefix">install_prefix</a>, <a href="#cmake_external-interface_libraries">interface_libraries</a>, <a href="#cmake_external-lib_name">lib_name</a>, <a href="#cmake_external-lib_source">lib_source</a>, <a href="#cmake_external-linkopts">linkopts</a>, <a href="#cmake_external-make_commands">make_commands</a>,
               <a href="#cmake_external-out_bin_dir">out_bin_dir</a>, <a href="#cmake_external-out_include_dir">out_include_dir</a>, <a href="#cmake_external-out_lib_dir">out_lib_dir</a>, <a href="#cmake_external-postfix_script">postfix_script</a>, <a href="#cmake_external-shared_libraries">shared_libraries</a>,
               <a href="#cmake_external-static_libraries">static_libraries</a>, <a href="#cmake_external-tools_deps">tools_deps</a>, <a href="#cmake_external-working_directory">working_directory</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cmake_external-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="cmake_external-additional_inputs"></a>additional_inputs |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="cmake_external-additional_tools"></a>additional_tools |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="cmake_external-alwayslink"></a>alwayslink |  -   | Boolean | optional | False |
| <a id="cmake_external-binaries"></a>binaries |  -   | List of strings | optional | [] |
| <a id="cmake_external-cache_entries"></a>cache_entries |  -   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="cmake_external-cmake_options"></a>cmake_options |  -   | List of strings | optional | [] |
| <a id="cmake_external-defines"></a>defines |  -   | List of strings | optional | [] |
| <a id="cmake_external-deps"></a>deps |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="cmake_external-env_vars"></a>env_vars |  -   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="cmake_external-generate_crosstool_file"></a>generate_crosstool_file |  -   | Boolean | optional | False |
| <a id="cmake_external-headers_only"></a>headers_only |  -   | Boolean | optional | False |
| <a id="cmake_external-install_prefix"></a>install_prefix |  -   | String | optional | "" |
| <a id="cmake_external-interface_libraries"></a>interface_libraries |  -   | List of strings | optional | [] |
| <a id="cmake_external-lib_name"></a>lib_name |  -   | String | optional | "" |
| <a id="cmake_external-lib_source"></a>lib_source |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="cmake_external-linkopts"></a>linkopts |  -   | List of strings | optional | [] |
| <a id="cmake_external-make_commands"></a>make_commands |  -   | List of strings | optional | ["make", "make install"] |
| <a id="cmake_external-out_bin_dir"></a>out_bin_dir |  -   | String | optional | "bin" |
| <a id="cmake_external-out_include_dir"></a>out_include_dir |  -   | String | optional | "include" |
| <a id="cmake_external-out_lib_dir"></a>out_lib_dir |  -   | String | optional | "lib" |
| <a id="cmake_external-postfix_script"></a>postfix_script |  -   | String | optional | "" |
| <a id="cmake_external-shared_libraries"></a>shared_libraries |  -   | List of strings | optional | [] |
| <a id="cmake_external-static_libraries"></a>static_libraries |  -   | List of strings | optional | [] |
| <a id="cmake_external-tools_deps"></a>tools_deps |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="cmake_external-working_directory"></a>working_directory |  -   | String | optional | "" |


<a id="#configure_make"></a>

## configure_make

<pre>
configure_make(<a href="#configure_make-name">name</a>, <a href="#configure_make-additional_inputs">additional_inputs</a>, <a href="#configure_make-additional_tools">additional_tools</a>, <a href="#configure_make-alwayslink">alwayslink</a>, <a href="#configure_make-autogen">autogen</a>, <a href="#configure_make-autogen_command">autogen_command</a>,
               <a href="#configure_make-autogen_env_vars">autogen_env_vars</a>, <a href="#configure_make-autogen_options">autogen_options</a>, <a href="#configure_make-autoreconf">autoreconf</a>, <a href="#configure_make-autoreconf_env_vars">autoreconf_env_vars</a>, <a href="#configure_make-autoreconf_options">autoreconf_options</a>,
               <a href="#configure_make-binaries">binaries</a>, <a href="#configure_make-configure_command">configure_command</a>, <a href="#configure_make-configure_env_vars">configure_env_vars</a>, <a href="#configure_make-configure_in_place">configure_in_place</a>, <a href="#configure_make-configure_options">configure_options</a>,
               <a href="#configure_make-defines">defines</a>, <a href="#configure_make-deps">deps</a>, <a href="#configure_make-headers_only">headers_only</a>, <a href="#configure_make-install_prefix">install_prefix</a>, <a href="#configure_make-interface_libraries">interface_libraries</a>, <a href="#configure_make-lib_name">lib_name</a>, <a href="#configure_make-lib_source">lib_source</a>,
               <a href="#configure_make-linkopts">linkopts</a>, <a href="#configure_make-make_commands">make_commands</a>, <a href="#configure_make-out_bin_dir">out_bin_dir</a>, <a href="#configure_make-out_include_dir">out_include_dir</a>, <a href="#configure_make-out_lib_dir">out_lib_dir</a>, <a href="#configure_make-postfix_script">postfix_script</a>,
               <a href="#configure_make-shared_libraries">shared_libraries</a>, <a href="#configure_make-static_libraries">static_libraries</a>, <a href="#configure_make-tools_deps">tools_deps</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="configure_make-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="configure_make-additional_inputs"></a>additional_inputs |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="configure_make-additional_tools"></a>additional_tools |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="configure_make-alwayslink"></a>alwayslink |  -   | Boolean | optional | False |
| <a id="configure_make-autogen"></a>autogen |  -   | Boolean | optional | False |
| <a id="configure_make-autogen_command"></a>autogen_command |  -   | String | optional | "autogen.sh" |
| <a id="configure_make-autogen_env_vars"></a>autogen_env_vars |  -   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="configure_make-autogen_options"></a>autogen_options |  -   | List of strings | optional | [] |
| <a id="configure_make-autoreconf"></a>autoreconf |  -   | Boolean | optional | False |
| <a id="configure_make-autoreconf_env_vars"></a>autoreconf_env_vars |  -   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="configure_make-autoreconf_options"></a>autoreconf_options |  -   | List of strings | optional | [] |
| <a id="configure_make-binaries"></a>binaries |  -   | List of strings | optional | [] |
| <a id="configure_make-configure_command"></a>configure_command |  -   | String | optional | "configure" |
| <a id="configure_make-configure_env_vars"></a>configure_env_vars |  -   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="configure_make-configure_in_place"></a>configure_in_place |  -   | Boolean | optional | False |
| <a id="configure_make-configure_options"></a>configure_options |  -   | List of strings | optional | [] |
| <a id="configure_make-defines"></a>defines |  -   | List of strings | optional | [] |
| <a id="configure_make-deps"></a>deps |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="configure_make-headers_only"></a>headers_only |  -   | Boolean | optional | False |
| <a id="configure_make-install_prefix"></a>install_prefix |  -   | String | optional | "" |
| <a id="configure_make-interface_libraries"></a>interface_libraries |  -   | List of strings | optional | [] |
| <a id="configure_make-lib_name"></a>lib_name |  -   | String | optional | "" |
| <a id="configure_make-lib_source"></a>lib_source |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="configure_make-linkopts"></a>linkopts |  -   | List of strings | optional | [] |
| <a id="configure_make-make_commands"></a>make_commands |  -   | List of strings | optional | ["make", "make install"] |
| <a id="configure_make-out_bin_dir"></a>out_bin_dir |  -   | String | optional | "bin" |
| <a id="configure_make-out_include_dir"></a>out_include_dir |  -   | String | optional | "include" |
| <a id="configure_make-out_lib_dir"></a>out_lib_dir |  -   | String | optional | "lib" |
| <a id="configure_make-postfix_script"></a>postfix_script |  -   | String | optional | "" |
| <a id="configure_make-shared_libraries"></a>shared_libraries |  -   | List of strings | optional | [] |
| <a id="configure_make-static_libraries"></a>static_libraries |  -   | List of strings | optional | [] |
| <a id="configure_make-tools_deps"></a>tools_deps |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |


<a id="#make"></a>

## make

<pre>
make(<a href="#make-name">name</a>, <a href="#make-additional_inputs">additional_inputs</a>, <a href="#make-additional_tools">additional_tools</a>, <a href="#make-alwayslink">alwayslink</a>, <a href="#make-binaries">binaries</a>, <a href="#make-defines">defines</a>, <a href="#make-deps">deps</a>, <a href="#make-headers_only">headers_only</a>,
     <a href="#make-interface_libraries">interface_libraries</a>, <a href="#make-keep_going">keep_going</a>, <a href="#make-lib_name">lib_name</a>, <a href="#make-lib_source">lib_source</a>, <a href="#make-linkopts">linkopts</a>, <a href="#make-make_commands">make_commands</a>, <a href="#make-make_env_vars">make_env_vars</a>,
     <a href="#make-out_bin_dir">out_bin_dir</a>, <a href="#make-out_include_dir">out_include_dir</a>, <a href="#make-out_lib_dir">out_lib_dir</a>, <a href="#make-postfix_script">postfix_script</a>, <a href="#make-prefix">prefix</a>, <a href="#make-shared_libraries">shared_libraries</a>,
     <a href="#make-static_libraries">static_libraries</a>, <a href="#make-tools_deps">tools_deps</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="make-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="make-additional_inputs"></a>additional_inputs |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="make-additional_tools"></a>additional_tools |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="make-alwayslink"></a>alwayslink |  -   | Boolean | optional | False |
| <a id="make-binaries"></a>binaries |  -   | List of strings | optional | [] |
| <a id="make-defines"></a>defines |  -   | List of strings | optional | [] |
| <a id="make-deps"></a>deps |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="make-headers_only"></a>headers_only |  -   | Boolean | optional | False |
| <a id="make-interface_libraries"></a>interface_libraries |  -   | List of strings | optional | [] |
| <a id="make-keep_going"></a>keep_going |  -   | Boolean | optional | True |
| <a id="make-lib_name"></a>lib_name |  -   | String | optional | "" |
| <a id="make-lib_source"></a>lib_source |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="make-linkopts"></a>linkopts |  -   | List of strings | optional | [] |
| <a id="make-make_commands"></a>make_commands |  -   | List of strings | optional | [] |
| <a id="make-make_env_vars"></a>make_env_vars |  -   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="make-out_bin_dir"></a>out_bin_dir |  -   | String | optional | "bin" |
| <a id="make-out_include_dir"></a>out_include_dir |  -   | String | optional | "include" |
| <a id="make-out_lib_dir"></a>out_lib_dir |  -   | String | optional | "lib" |
| <a id="make-postfix_script"></a>postfix_script |  -   | String | optional | "" |
| <a id="make-prefix"></a>prefix |  -   | String | optional | "" |
| <a id="make-shared_libraries"></a>shared_libraries |  -   | List of strings | optional | [] |
| <a id="make-static_libraries"></a>static_libraries |  -   | List of strings | optional | [] |
| <a id="make-tools_deps"></a>tools_deps |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |


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
ForeignCcArtifact(<a href="#ForeignCcArtifact-gen_dir">gen_dir</a>, <a href="#ForeignCcArtifact-bin_dir_name">bin_dir_name</a>, <a href="#ForeignCcArtifact-lib_dir_name">lib_dir_name</a>, <a href="#ForeignCcArtifact-include_dir_name">include_dir_name</a>)
</pre>

Groups information about the external library install directory,
and relative bin, include and lib directories.

Serves to pass transitive information about externally built artifacts up the dependency chain.

Can not be used as a top-level provider.
Instances of ForeignCcArtifact are incapsulated in a depset ForeignCcDeps#artifacts.

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="ForeignCcArtifact-gen_dir"></a>gen_dir |  Install directory    |
| <a id="ForeignCcArtifact-bin_dir_name"></a>bin_dir_name |  Bin directory, relative to install directory    |
| <a id="ForeignCcArtifact-lib_dir_name"></a>lib_dir_name |  Lib directory, relative to install directory    |
| <a id="ForeignCcArtifact-include_dir_name"></a>include_dir_name |  Include directory, relative to install directory    |


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

Provider to keep different kinds of input files, directories,
and C/C++ compilation and linking info from dependencies

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


<a id="#WrappedOutputs"></a>

## WrappedOutputs

<pre>
WrappedOutputs(<a href="#WrappedOutputs-script_file">script_file</a>, <a href="#WrappedOutputs-log_file">log_file</a>, <a href="#WrappedOutputs-wrapper_script_file">wrapper_script_file</a>, <a href="#WrappedOutputs-wrapper_script">wrapper_script</a>)
</pre>

Structure for passing the log and scripts file information, and wrapper script text.

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="WrappedOutputs-script_file"></a>script_file |  Main script file    |
| <a id="WrappedOutputs-log_file"></a>log_file |  Execution log file    |
| <a id="WrappedOutputs-wrapper_script_file"></a>wrapper_script_file |  Wrapper script file (output for debugging purposes)    |
| <a id="WrappedOutputs-wrapper_script"></a>wrapper_script |  Wrapper script text to execute    |


<a id="#rules_foreign_cc_dependencies"></a>

## rules_foreign_cc_dependencies

<pre>
rules_foreign_cc_dependencies(<a href="#rules_foreign_cc_dependencies-native_tools_toolchains">native_tools_toolchains</a>, <a href="#rules_foreign_cc_dependencies-register_default_tools">register_default_tools</a>,
                              <a href="#rules_foreign_cc_dependencies-additonal_shell_toolchain_mappings">additonal_shell_toolchain_mappings</a>, <a href="#rules_foreign_cc_dependencies-additonal_shell_toolchain_package">additonal_shell_toolchain_package</a>)
</pre>

Call this function from the WORKSPACE file to initialize rules_foreign_cc     dependencies and let neccesary code generation happen     (Code generation is needed to support different variants of the C++ Starlark API.).

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="rules_foreign_cc_dependencies-native_tools_toolchains"></a>native_tools_toolchains |  pass the toolchains for toolchain types     '@rules_foreign_cc//tools/build_defs:cmake_toolchain' and     '@rules_foreign_cc//tools/build_defs:ninja_toolchain' with the needed platform constraints.     If you do not pass anything, registered default toolchains will be selected (see below).   |  <code>[]</code> |
| <a id="rules_foreign_cc_dependencies-register_default_tools"></a>register_default_tools |  If True, the cmake and ninja toolchains, calling corresponding     preinstalled binaries by name (cmake, ninja) will be registered after     'native_tools_toolchains' without any platform constraints. The default is True.   |  <code>True</code> |
| <a id="rules_foreign_cc_dependencies-additonal_shell_toolchain_mappings"></a>additonal_shell_toolchain_mappings |  Mappings of the shell toolchain functions to     execution and target platforms constraints. Similar to what defined in     @rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:toolchain_mappings.bzl     in the TOOLCHAIN_MAPPINGS list. Please refer to example in @rules_foreign_cc//toolchain_examples.   |  <code>[]</code> |
| <a id="rules_foreign_cc_dependencies-additonal_shell_toolchain_package"></a>additonal_shell_toolchain_package |  A package under which additional toolchains, referencing     the generated data for the passed additonal_shell_toolchain_mappings, will be defined.     This value is needed since register_toolchains() is called for these toolchains.     Please refer to example in @rules_foreign_cc//toolchain_examples.   |  <code>None</code> |


