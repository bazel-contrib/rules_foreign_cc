""" Contains definitions for creation of external C/C++ build rules (for building external libraries
 with CMake, configure/make, autotools)
"""

load("@bazel_skylib//lib:collections.bzl", "collections")
load(
    "//tools/build_defs:cc_toolchain_util.bzl",
    "LibrariesToLinkInfo",
    "create_linking_info",
    "get_env_vars",
    "targets_windows",
)
load("//tools/build_defs:detect_root.bzl", "detect_root")

""" Dict with definitions of the context attributes, that customize cc_external_rule_impl function.
 Many of the attributes have default values.

 Typically, the concrete external library rule will use this structure to create the attributes
 description dict. See cmake.bzl as an example.
"""
CC_EXTERNAL_RULE_ATTRIBUTES = {
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
    # Flag variable to indicate that the library produces only headers
    "headers_only": attr.bool(mandatory = False, default = False),
    #
    # link to the shell utilities used by the shell script in cc_external_rule_impl.
    "_utils": attr.label(
        default = "@foreign_cc_platform_utils//:shell_utils",
        allow_single_file = True,
    ),
    # link to the shell utilities used by the shell script in cc_external_rule_impl.
    "_target_os": attr.label(
        default = "@foreign_cc_platform_utils//:target_os",
    ),
    # we need to declare this attribute to access cc_toolchain
    "_cc_toolchain": attr.label(default = Label("@bazel_tools//tools/cpp:current_cc_toolchain")),
}

def create_attrs(attr_struct, configure_name, configure_script, **kwargs):
    """ Function for adding/modifying context attributes struct (originally from ctx.attr),
     provided by user, to be passed to the cc_external_rule_impl function as a struct.

     Copies a struct 'attr_struct' values (with attributes from CC_EXTERNAL_RULE_ATTRIBUTES)
     to the resulting struct, adding or replacing attributes passed in 'configure_name',
     'configure_script', and '**kwargs' parameters.
    """
    dict = {}
    for key in CC_EXTERNAL_RULE_ATTRIBUTES:
        if not key.startswith("_") and hasattr(attr_struct, key):
            dict[key] = getattr(attr_struct, key)

    dict["configure_name"] = configure_name
    dict["configure_script"] = configure_script

    for arg in kwargs:
        dict[arg] = kwargs[arg]
    return struct(**dict)

def cc_external_rule_impl(ctx, attrs):
    """ Framework function for performing external C/C++ building.

     To be used to build external libraries or/and binaries with CMake, configure/make, autotools etc.,
     and use results in Bazel.
     It is possible to use it to build a group of external libraries, that depend on each other or on
     Bazel library, and pass nessesary tools.

     Accepts the actual commands for build configuration/execution in attrs.

     Creates and runs a shell script, which:

     1) prepares directory structure with sources, dependencies, and tools symlinked into subdirectories
      of the execroot directory. Adds tools into PATH.
     2) defines the correct absolute paths in tools with the script paths, see 7
     3) defines the following environment variables:
        EXT_BUILD_ROOT: execroot directory
        EXT_BUILD_DEPS: subdirectory of execroot, which contains the following subdirectories:

          For cmake_external built dependencies:
            symlinked install directories of the dependencies

          for Bazel built/imported dependencies:

            include - here the include directories are symlinked
            lib - here the library files are symlinked
            lib/pkgconfig - here the pkgconfig files are symlinked
            bin - here the tools are copied
        INSTALLDIR: subdirectory of the execroot (named by the lib_name), where the library/binary
        will be installed

        These variables should be used by the calling rule to refer to the created directory structure.
     4) calls 'attrs.configure_script'
     5) calls 'attrs.make_commands'
     6) calls 'attrs.postfix_script'
     7) replaces absolute paths in possibly created scripts with a placeholder value

     Please see cmake.bzl for example usage.

     Args:
       ctx: calling rule context
       attrs: struct with fields from CC_EXTERNAL_RULE_ATTRIBUTES (see descriptions there), and
         two mandatory fields:
         configure_name: name of the configuration tool, to be used in action mnemonic
         configure_script: actual configuration script
       All other fields are ignored.
    """
    lib_name = _value(attrs.lib_name, ctx.attr.name)

    inputs = _define_inputs(attrs)
    outputs = _define_outputs(ctx, attrs, lib_name)
    out_cc_info = _define_out_cc_info(ctx, attrs, inputs, outputs)

    shell_utils = ctx.attr._utils.files.to_list()[0].path

    script_lines = [
        "echo \"Building external library '{}'\"".format(lib_name),
        "set -e",
        "source " + shell_utils,
        "set_platform_env_vars",
        "export EXT_BUILD_ROOT=$BUILD_PWD",
        "export BUILD_TMPDIR=$(mktemp -d)",
        "export EXT_BUILD_DEPS=$EXT_BUILD_ROOT/bazel_foreign_cc_deps",
        "mkdir -p $EXT_BUILD_DEPS",
        "export INSTALLDIR=$EXT_BUILD_ROOT/" + outputs.installdir.path,
        "mkdir -p $INSTALLDIR",
        "echo \"Environment:______________\"",
        "env",
        "echo \"__________________________\"",
        "trap \"{ rm -rf $BUILD_TMPDIR $EXT_BUILD_ROOT/bazel_foreign_cc_deps; }\" EXIT",
        "\n".join(_copy_deps_and_tools(inputs)),
        "define_absolute_paths $EXT_BUILD_ROOT/bin $EXT_BUILD_ROOT/bin",
        "pushd $BUILD_TMPDIR",
        attrs.configure_script,
        "\n".join(attrs.make_commands),
        _value(attrs.postfix_script, ""),
        "replace_absolute_paths $INSTALLDIR $INSTALLDIR",
        "popd",
    ]

    script_text = "\n".join(script_lines)
    print("script text: " + script_text)

    env = get_env_vars(ctx)
    execution_requirements = {"block-network": ""}

    ctx.actions.run_shell(
        mnemonic = "Cc" + attrs.configure_name.capitalize() + "MakeRule",
        inputs = depset(inputs.declared_inputs) + ctx.attr._cc_toolchain.files,
        outputs = outputs.declared_outputs,
        tools = ctx.attr._utils.files,
        # We should take the default PATH passed by Bazel, not that from cc_toolchain
        # for Windows, because the PATH under msys2 is different and that is which we need
        # for shell commands
        use_default_shell_env = targets_windows(ctx, None),
        command = script_text,
        execution_requirements = execution_requirements,
        env = env,
    )

    return [
        DefaultInfo(files = depset(direct = outputs.declared_outputs)),
        OutputGroupInfo(
            gen_dir = depset([outputs.installdir]),
            bin_dir = depset([outputs.out_bin_dir]),
            out_binary_files = depset(outputs.out_binary_files),
        ),
        cc_common.create_cc_skylark_info(ctx = ctx),
        out_cc_info.compilation_info,
        out_cc_info.linking_info,
    ]

def _value(value, default_value):
    if (value):
        return value
    return default_value

def _depset(item):
    if item == None:
        return depset()
    return depset([item])

def _list(item):
    if item:
        return [item]
    return []

def _copy_deps_and_tools(files):
    list = []
    list += _symlink_to_dir("lib", files.libs, False)
    list += _symlink_to_dir("include", files.headers, True)

    list += _symlink_to_dir("bin", files.tools_files, False)

    for ext_dir in files.ext_build_dirs:
        list += ["symlink_to_dir $EXT_BUILD_ROOT/{} $EXT_BUILD_DEPS".format(_file_path(ext_dir))]

    list += ["if [ -d $EXT_BUILD_DEPS/bin ]; then"]

    list += ["  tools=$(find $EXT_BUILD_DEPS/bin -maxdepth 1 -mindepth 1)"]
    list += ["  for tool in $tools;"]
    list += ["  do"]
    list += ["    if  [[ -d \"$tool\" ]] || [[ -L \"$tool\" ]]; then"]
    list += ["      export PATH=$PATH:$tool"]
    list += ["    fi"]
    list += ["  done"]
    list += ["fi"]
    list += ["path $EXT_BUILD_DEPS/bin"]

    return list

def _symlink_to_dir(dir_name, files_list, link_children):
    if len(files_list) == 0:
        return []
    list = ["mkdir -p $EXT_BUILD_DEPS/" + dir_name]

    paths_list = []
    for file in files_list:
        paths_list += [_file_path(file)]

    link_function = "symlink_contents_to_dir" if link_children else "symlink_to_dir"
    for path in paths_list:
        list += ["{} $EXT_BUILD_ROOT/{} $EXT_BUILD_DEPS/{}".format(link_function, path, dir_name)]

    return list

def _file_path(file):
    return file if type(file) == "string" else file.path

def _check_file_name(var, name):
    if (len(var) == 0):
        fail("{} can not be empty string.".format(name.capitalize()))

    if (not var[0:1].isalpha()):
        fail("{} should start with a letter.".format(name.capitalize()))
    for index in range(1, len(var) - 1):
        letter = var[index]
        if not letter.isalnum() and letter != "_":
            fail("{} should be alphanumeric or '_'.".format(name.capitalize()))

_Outputs = provider(
    doc = "Provider to keep different kinds of the external build output files and directories",
    fields = dict(
        installdir = "Directory, where the library or binary is installed",
        out_include_dir = "Directory with header files (relative to install directory)",
        out_bin_dir = "Directory with binary files (relative to install directory)",
        out_lib_dir = "Directory with library files (relative to install directory)",
        out_binary_files = "Binary files, which will be created by the action",
        libraries = "Library files, which will be created by the action",
        declared_outputs = "All output files and directories of the action",
    ),
)

def _define_outputs(ctx, attrs, lib_name):
    static_libraries = []
    if not hasattr(attrs, "headers_only") or not attrs.headers_only:
        if (not (hasattr(attrs, "static_libraries") and len(attrs.static_libraries) > 0) and
            not (hasattr(attrs, "shared_libraries") and len(attrs.shared_libraries) > 0) and
            not (hasattr(attrs, "interface_libraries") and len(attrs.interface_libraries) > 0) and
            not (hasattr(attrs, "binaries") and len(attrs.binaries) > 0)):
            static_libraries = [lib_name + (".lib" if targets_windows(ctx, None) else ".a")]
        else:
            static_libraries = attrs.static_libraries

    _check_file_name(lib_name, "Library name")

    out_binary_files = []
    for file in attrs.binaries:
        out_binary_files += [_declare_out(ctx, lib_name, attrs.out_bin_dir, file)]

    installdir = ctx.actions.declare_directory(lib_name)
    out_include_dir = ctx.actions.declare_directory(lib_name + "/" + attrs.out_include_dir)
    out_bin_dir = ctx.actions.declare_directory(lib_name + "/" + attrs.out_bin_dir)
    out_lib_dir = ctx.actions.declare_directory(lib_name + "/" + attrs.out_lib_dir)

    libraries = LibrariesToLinkInfo(
        static_libraries = _declare_out(ctx, lib_name, out_lib_dir, static_libraries),
        shared_libraries = _declare_out(ctx, lib_name, out_lib_dir, attrs.shared_libraries),
        interface_libraries = _declare_out(ctx, lib_name, out_lib_dir, attrs.interface_libraries),
    )
    declared_outputs = [installdir, out_include_dir, out_bin_dir, out_lib_dir] + out_binary_files
    declared_outputs += libraries.static_libraries
    declared_outputs += libraries.shared_libraries + libraries.interface_libraries

    return _Outputs(
        installdir = installdir,
        out_include_dir = out_include_dir,
        out_bin_dir = out_bin_dir,
        out_lib_dir = out_lib_dir,
        out_binary_files = out_binary_files,
        libraries = libraries,
        declared_outputs = declared_outputs,
    )

def _declare_out(ctx, lib_name, dir, files):
    if files and len(files) > 0:
        return [ctx.actions.declare_file("/".join([lib_name, dir.basename, file])) for file in files]
    return []

_InputFiles = provider(
    doc = """Provider to keep different kinds of input files, directories,
and C/C++ compilation and linking info from dependencies""",
    fields = dict(
        headers = """Include directories to be used for compilation.
Will be copied into $EXT_BUILD_DEPS/include.""",
        libs = "Library files to be used for building. Will be copied into $EXT_BUILD_DEPS/lib.",
        deps_linkopts = "Link options from deps to be passed to resulting CcLinkingInfo",
        tools_files = """Files and directories with tools needed for configuration/building
to be copied into the bin folder, which is added to the PATH""",
        ext_build_dirs = """Directories with libraries, built by framework function.
This directories should be copied into $EXT_BUILD_DEPS/lib-name as is, with all contents.""",
        deps_compilation_info = "Merged CcCompilationInfo from deps attribute",
        deps_linking_info = "Merged CcLinkingInfo from deps attribute",
        declared_inputs = "All files and directories that must be declared as action inputs",
    ),
)

def _define_inputs(attrs):
    compilation_infos_ext = []
    linking_infos_ext = []
    compilation_infos_bazel = []
    linking_infos_bazel = []

    # This framework function-built libraries: copy result directories under
    # $EXT_BUILD_DEPS/lib-name
    ext_build_dirs = []

    for dep in attrs.deps:
        provider = dep[OutputGroupInfo]
        ext_built = provider and hasattr(provider, "gen_dir")

        if ext_built:
            ext_build_dirs += provider.gen_dir.to_list()
            compilation_infos_ext += [dep[CcCompilationInfo]]
            linking_infos_ext += [dep[CcLinkingInfo]]
        else:
            compilation_infos_bazel += [dep[CcCompilationInfo]]
            linking_infos_bazel += [dep[CcLinkingInfo]]

    tools_roots = []
    tools_files = []
    for tool in attrs.tools_deps:
        tool_root = detect_root(tool)
        tools_roots += [tool_root]
        for file_list in tool.files.to_list():
            tools_files += _list(file_list)

    for tool in attrs.additional_tools:
        for file_list in tool.files.to_list():
            tools_files += _list(file_list)

    # For Bazel-built libraries: copy headers and libs.
    headers = [_get_headers(cc_info) for cc_info in compilation_infos_bazel]
    deps_linking_bazel = cc_common.merge_cc_linking_infos(cc_linking_infos = linking_infos_bazel)
    libs = _collect_libs(deps_linking_bazel)

    # These variables are needed for correct C/C++ providers constraction,
    # they should contain all libraries and include directories.
    deps_compilation = cc_common.merge_cc_compilation_infos(cc_compilation_infos = compilation_infos_ext + compilation_infos_bazel)
    deps_linking = cc_common.merge_cc_linking_infos(cc_linking_infos = linking_infos_ext + [deps_linking_bazel])

    # Pass flags up the dependency chain for all types of libraries;
    # flags are passed uniformly for Bazel-built and external libraries
    linkopts = _collect_flags(deps_linking)

    return _InputFiles(
        headers = headers,
        libs = libs,
        deps_linkopts = linkopts,
        tools_files = tools_roots,
        deps_compilation_info = deps_compilation,
        deps_linking_info = deps_linking,
        ext_build_dirs = ext_build_dirs,
        declared_inputs = depset(attrs.lib_source.files) + libs + tools_files +
                          attrs.additional_inputs + deps_compilation.headers + ext_build_dirs,
    )

def _get_headers(compilation_info):
    include_dirs = collections.uniq(compilation_info.system_includes.to_list())
    headers = []
    for header in compilation_info.headers:
        path = header.path
        included = False
        for dir in include_dirs:
            if path.startswith(dir):
                included = True
                break
        if not included:
            headers += [header]
    return headers + include_dirs

def _define_out_cc_info(ctx, attrs, inputs, outputs):
    compilation_info = CcCompilationInfo(
        headers = depset([outputs.out_include_dir]),
        system_includes = depset([outputs.out_include_dir.path]),
        defines = depset(attrs.defines),
    )
    out_compilation_info = cc_common.merge_cc_compilation_infos(
        cc_compilation_infos = [inputs.deps_compilation_info, compilation_info],
    )

    linkopts = depset(direct = attrs.linkopts, transitive = [depset(inputs.deps_linkopts)])
    linking_info = create_linking_info(ctx, linkopts, outputs.libraries)
    out_linking_info = cc_common.merge_cc_linking_infos(
        cc_linking_infos = [inputs.deps_linking_info, linking_info],
    )

    return struct(
        compilation_info = out_compilation_info,
        linking_info = out_linking_info,
    )

def _extract_link_params(cc_linking):
    return [
        cc_linking.static_mode_params_for_dynamic_library,
        cc_linking.static_mode_params_for_executable,
        cc_linking.dynamic_mode_params_for_dynamic_library,
        cc_linking.dynamic_mode_params_for_executable,
    ]

def _collect_libs(cc_linking):
    libs = []
    for params in _extract_link_params(cc_linking):
        libs += [lib.artifact() for lib in params.libraries_to_link.to_list()]
        libs += params.dynamic_libraries_for_runtime.to_list()
    return collections.uniq(libs)

def _collect_flags(cc_linking):
    linkopts = []
    for params in _extract_link_params(cc_linking):
        linkopts = params.linkopts.to_list()
    return collections.uniq(linkopts)
