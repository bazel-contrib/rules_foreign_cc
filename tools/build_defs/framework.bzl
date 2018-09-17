""" Contains definitions for creation of external C/C++ build rules (for building external libraries
 with CMake, configure/make, autotools)
"""

load("@bazel_skylib//lib:collections.bzl", "collections")
load(":version.bzl", "VERSION")
load(
    "//tools/build_defs:cc_toolchain_util.bzl",
    "LibrariesToLinkInfo",
    "create_linking_info",
    "get_env_vars",
    "targets_windows",
)
load("//tools/build_defs:detect_root.bzl", "detect_root")
load("@foreign_cc_platform_utils//:os_info.bzl", "OSInfo")

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
    "_is_debug": attr.label(
        default = "@foreign_cc_platform_utils//:compilation_mode",
    ),
    # link to the shell utilities used by the shell script in cc_external_rule_impl.
    "_target_os": attr.label(
        default = "@foreign_cc_platform_utils//:target_os",
    ),
    # we need to declare this attribute to access cc_toolchain
    "_cc_toolchain": attr.label(default = Label("@bazel_tools//tools/cpp:current_cc_toolchain")),
}

def create_attrs(attr_struct, configure_name, create_configure_script, **kwargs):
    """ Function for adding/modifying context attributes struct (originally from ctx.attr),
     provided by user, to be passed to the cc_external_rule_impl function as a struct.

     Copies a struct 'attr_struct' values (with attributes from CC_EXTERNAL_RULE_ATTRIBUTES)
     to the resulting struct, adding or replacing attributes passed in 'configure_name',
     'configure_script', and '**kwargs' parameters.
    """
    attrs = {}
    for key in CC_EXTERNAL_RULE_ATTRIBUTES:
        if not key.startswith("_") and hasattr(attr_struct, key):
            attrs[key] = getattr(attr_struct, key)

    attrs["configure_name"] = configure_name
    attrs["create_configure_script"] = create_configure_script

    for arg in kwargs:
        attrs[arg] = kwargs[arg]
    return struct(**attrs)

ForeignCcDeps = provider(
    doc = """Provider to pass transitive information about external libraries.""",
    fields = {"artifacts": "Depset of ForeignCcArtifact"},
)

ForeignCcArtifact = provider(
    doc = """Groups information about the external library install directory,
and relative bin, include and lib directories.

Serves to pass transitive information about externally built artifacts up the dependency chain.

Can not be used as a top-level provider.
Instances of ForeignCcArtifact are incapsulated in a depset ForeignCcDeps#artifacts.""",
    fields = {
        "gen_dir": "Install directory",
        "bin_dir_name": "Bin directory, relative to install directory",
        "lib_dir_name": "Lib directory, relative to install directory",
        "include_dir_name": "Include directory, relative to install directory",
        "declared_outputs": "List of files that must be generated",
    },
)

ConfigureParameters = provider(
    doc = """Parameters of create_configure_script callback function, called by
cc_external_rule_impl function. create_configure_script creates the configuration part
of the script, and allows to reuse the inputs structure, created by the framework.""",
    fields = dict(
        ctx = "Rule context",
        attrs = """Attributes struct, created by create_attrs function above""",
        inputs = """InputFiles provider: summarized information on rule inputs, created by framework
function, to be reused in script creator. Contains in particular merged compilation and linking
dependencies.""",
    ),
)

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
     4) calls 'attrs.create_configure_script'
     5) calls 'attrs.make_commands'
     6) calls 'attrs.postfix_script'
     7) replaces absolute paths in possibly created scripts with a placeholder value

     Please see cmake.bzl for example usage.

     Args:
       ctx: calling rule context
       attrs: attributes struct, created by create_attrs function above.
         Contains fields from CC_EXTERNAL_RULE_ATTRIBUTES (see descriptions there),
         two mandatory fields:
         -  configure_name: name of the configuration tool, to be used in action mnemonic,
         -  create_configure_script(ConfigureParameters): function that creates configuration
            script, accepts ConfigureParameters
         and some other fields provided by the rule, which have been passed to create_attrs.
    """
    lib_name = _value(attrs.lib_name, ctx.attr.name)

    inputs = _define_inputs(attrs)
    outputs = _define_outputs(ctx, attrs, lib_name)
    out_cc_info = _define_out_cc_info(ctx, attrs, inputs, outputs)

    shell_utils = ctx.attr._utils.files.to_list()[0].path

    env = _correct_path_variable(get_env_vars(ctx))
    set_envs = ""
    if not ctx.attr._target_os[OSInfo].is_osx:
        set_envs = "\n".join(["export {}=\"{}\"".format(key, env[key]) for key in env])

    version_and_lib = "Bazel external C/C++ Rules #{}. Building library '{}'".format(VERSION, lib_name)

    script_lines = [
        "echo \"\n{}\n\"".format(version_and_lib),
        "set -e",
        "source " + shell_utils,
        set_envs,
        "set_platform_env_vars",
        "export EXT_BUILD_ROOT=$BUILD_PWD",
        "export BUILD_TMPDIR=$(mktemp -d)",
        "export EXT_BUILD_DEPS=$EXT_BUILD_ROOT/bazel_foreign_cc_deps_" + lib_name,
        "mkdir -p $EXT_BUILD_DEPS",
        "export INSTALLDIR=$EXT_BUILD_ROOT/" + outputs.installdir,
        "mkdir -p $INSTALLDIR",
        "echo \"Environment:______________\"",
        "env",
        "echo \"__________________________\"",
        "trap \"{ rm -rf $BUILD_TMPDIR $EXT_BUILD_ROOT/bazel_foreign_cc_deps_" + lib_name + "; }\" EXIT",
        "\n".join(_copy_deps_and_tools(inputs)),
        # replace placeholder with the dependencies root
        "define_absolute_paths $EXT_BUILD_DEPS $EXT_BUILD_DEPS",
        "pushd $BUILD_TMPDIR",
        attrs.create_configure_script(ConfigureParameters(ctx = ctx, attrs = attrs, inputs = inputs)),
        "\n".join(attrs.make_commands),
        _value(attrs.postfix_script, ""),
        # replace references to the root directory when building ($BUILD_TMPDIR)
        # and the root where the dependencies were installed ($EXT_BUILD_DEPS)
        # for the results which are in $INSTALLDIR (with placeholder)
        "replace_absolute_paths $INSTALLDIR $BUILD_TMPDIR",
        "replace_absolute_paths $INSTALLDIR $EXT_BUILD_DEPS",
        "popd",
    ]

    script_text = "\n".join(script_lines)
    print("script text: " + script_text)

    execution_requirements = {"block-network": ""}

    ctx.actions.run_shell(
        mnemonic = "Cc" + attrs.configure_name.capitalize() + "MakeRule",
        inputs = depset(inputs.declared_inputs) + ctx.attr._cc_toolchain.files,
        outputs = outputs.declared_outputs,
        tools = ctx.attr._utils.files,
        # We should take the default PATH passed by Bazel, not that from cc_toolchain
        # for Windows, because the PATH under msys2 is different and that is which we need
        # for shell commands
        use_default_shell_env = not ctx.attr._target_os[OSInfo].is_osx,
        command = script_text,
        execution_requirements = execution_requirements,
        # this is ignored if use_default_shell_env = True
        env = env,
    )

    externally_built = ForeignCcArtifact(
        gen_dir = outputs.installdir,
        bin_dir_name = attrs.out_bin_dir,
        lib_dir_name = attrs.out_lib_dir,
        include_dir_name = attrs.out_include_dir,
        declared_outputs = outputs.declared_outputs,
    )
    return [
        DefaultInfo(files = depset(direct = outputs.declared_outputs)),
        OutputGroupInfo(
            out_binary_files = depset(outputs.out_binary_files),
        ),
        ForeignCcDeps(artifacts = depset(
            [externally_built],
            transitive = _get_transitive_artifacts(attrs.deps),
        )),
        cc_common.create_cc_skylark_info(ctx = ctx),
        out_cc_info.compilation_info,
        out_cc_info.linking_info,
    ]

def _get_transitive_artifacts(deps):
    artifacts = []
    for dep in deps:
        foreign_dep = get_foreign_cc_dep(dep)
        if foreign_dep:
            artifacts += [foreign_dep.artifacts]
    return artifacts

def _correct_path_variable(env):
    value = env.get("PATH", "")
    if not value:
        return env
    value = env.get("PATH", "").replace("C:\\", "/c/")
    value = value.replace("\\", "/")
    value = value.replace(";", ":")
    env["PATH"] = "$PATH:" + value
    return env

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
    lines = []
    lines += _symlink_to_dir("lib", files.libs, False)
    lines += _symlink_to_dir("include", files.headers + files.include_dirs, True)

    lines += _symlink_to_dir("bin", files.tools_files, False)

    for ext_dir in files.ext_build_dirs:
        lines += ["symlink_to_dir $EXT_BUILD_ROOT/{} $EXT_BUILD_DEPS".format(_file_path(ext_dir))]

    lines += ["if [ -d $EXT_BUILD_DEPS/bin ]; then"]

    lines += ["  tools=$(find $EXT_BUILD_DEPS/bin -maxdepth 1 -mindepth 1)"]
    lines += ["  for tool in $tools;"]
    lines += ["  do"]
    lines += ["    if  [[ -d \"$tool\" ]] || [[ -L \"$tool\" ]]; then"]
    lines += ["      export PATH=$PATH:$tool"]
    lines += ["    fi"]
    lines += ["  done"]
    lines += ["fi"]
    lines += ["path $EXT_BUILD_DEPS/bin"]

    return lines

def _symlink_to_dir(dir_name, files_list, link_children):
    if len(files_list) == 0:
        return []
    lines = ["mkdir -p $EXT_BUILD_DEPS/" + dir_name]

    paths_list = []
    for file in files_list:
        paths_list += [_file_path(file)]

    link_function = "symlink_contents_to_dir" if link_children else "symlink_to_dir"
    for path in paths_list:
        lines += ["{} $EXT_BUILD_ROOT/{} $EXT_BUILD_DEPS/{}".format(link_function, path, dir_name)]

    return lines

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

    out_include_dir = ctx.actions.declare_directory(lib_name + "/" + attrs.out_include_dir)
    installdir = '/'.join(out_include_dir.path.split('/')[:-1])

    libraries = LibrariesToLinkInfo(
        static_libraries = _declare_out(ctx, lib_name, attrs.out_lib_dir, static_libraries),
        shared_libraries = _declare_out(ctx, lib_name, attrs.out_lib_dir, attrs.shared_libraries),
        interface_libraries = _declare_out(ctx, lib_name, attrs.out_lib_dir, attrs.interface_libraries),
    )
    declared_outputs = [out_include_dir] + out_binary_files
    declared_outputs += libraries.static_libraries
    declared_outputs += libraries.shared_libraries + libraries.interface_libraries

    return _Outputs(
        installdir = installdir,
        out_include_dir = out_include_dir,
        out_binary_files = out_binary_files,
        libraries = libraries,
        declared_outputs = declared_outputs,
    )

def _declare_out(ctx, lib_name, dir, files):
    if files and len(files) > 0:
        return [ctx.actions.declare_file("/".join([lib_name, dir, file])) for file in files]
    return []

InputFiles = provider(
    doc = """Provider to keep different kinds of input files, directories,
and C/C++ compilation and linking info from dependencies""",
    fields = dict(
        headers = """Include files built by Bazel. Will be copied into $EXT_BUILD_DEPS/include.""",
        include_dirs = """Include directories built by Bazel.
Will be copied into $EXT_BUILD_DEPS/include.""",
        libs = """Library files built by Bazel.
Will be copied into $EXT_BUILD_DEPS/lib.""",
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
    compilation_infos_all = []
    linking_infos_all = []

    bazel_headers = []
    bazel_system_includes = []
    bazel_libs = []

    # This framework function-built libraries: copy result directories under
    # $EXT_BUILD_DEPS/lib-name
    ext_build_dirs = []
    ext_build_files = []
    ext_build_dirs_set = {}

    for dep in attrs.deps:
        external_deps = get_foreign_cc_dep(dep)

        linking_infos_all += [dep[CcLinkingInfo]]
        compilation_infos_all += [dep[CcCompilationInfo]]

        if external_deps:
            for artifact in external_deps.artifacts:
                if not ext_build_dirs_set.get(artifact.gen_dir):
                    ext_build_dirs_set[artifact.gen_dir] = 1
                    ext_build_dirs += [artifact.gen_dir]
                    ext_build_files += artifact.declared_outputs
        else:
            headers_info = _get_headers(dep[CcCompilationInfo])
            bazel_headers += headers_info.headers
            bazel_system_includes += headers_info.include_dirs
            bazel_libs += _collect_libs(dep[CcLinkingInfo])

    tools_roots = []
    tools_files = []
    for tool in attrs.tools_deps:
        tool_root = detect_root(tool)
        tools_roots += [tool_root]
        for file_list in tool.files:
            tools_files += _list(file_list)

    for tool in attrs.additional_tools:
        for file_list in tool.files:
            tools_files += _list(file_list)

    # These variables are needed for correct C/C++ providers constraction,
    # they should contain all libraries and include directories.
    deps_compilation = cc_common.merge_cc_compilation_infos(cc_compilation_infos = compilation_infos_all)
    deps_linking = cc_common.merge_cc_linking_infos(cc_linking_infos = linking_infos_all)

    return InputFiles(
        headers = bazel_headers,
        include_dirs = bazel_system_includes,
        libs = bazel_libs,
        tools_files = tools_roots,
        deps_compilation_info = deps_compilation,
        deps_linking_info = deps_linking,
        ext_build_dirs = ext_build_dirs,
        declared_inputs = depset(attrs.lib_source.files) + bazel_libs + tools_files +
                          attrs.additional_inputs + deps_compilation.headers + ext_build_files,
    )

def get_foreign_cc_dep(dep):
    return dep[ForeignCcDeps] if ForeignCcDeps in dep else None

# consider optimization here to do not iterate both collections
def _get_headers(compilation_info):
    include_dirs = collections.uniq(compilation_info.system_includes.to_list())
    headers = []
    for header in compilation_info.headers:
        path = header.path
        included = False
        for dir_ in include_dirs:
            if path.startswith(dir_):
                included = True
                break
        if not included:
            headers += [header]
    return struct(
        headers = headers,
        include_dirs = include_dirs,
    )

def _define_out_cc_info(ctx, attrs, inputs, outputs):
    compilation_info = CcCompilationInfo(
        headers = depset([outputs.out_include_dir]),
        system_includes = depset([outputs.out_include_dir.path]),
        defines = depset(attrs.defines),
    )
    out_compilation_info = cc_common.merge_cc_compilation_infos(
        cc_compilation_infos = [inputs.deps_compilation_info, compilation_info],
    )

    linking_info = create_linking_info(ctx, depset(direct = attrs.linkopts), outputs.libraries)
    out_linking_info = cc_common.merge_cc_linking_infos(
        cc_linking_infos = [linking_info, inputs.deps_linking_info],
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
        libs += [lib.artifact() for lib in params.libraries_to_link]
        libs += params.dynamic_libraries_for_runtime.to_list()
    return collections.uniq(libs)
