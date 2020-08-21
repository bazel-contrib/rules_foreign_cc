""" Contains definitions for creation of external C/C++ build rules (for building external libraries
 with CMake, configure/make, autotools)
"""

load("@bazel_skylib//lib:collections.bzl", "collections")
load("@rules_foreign_cc//tools/build_defs:version.bzl", "VERSION")
load(
    ":cc_toolchain_util.bzl",
    "LibrariesToLinkInfo",
    "create_linking_info",
    "get_env_vars",
    "targets_windows",
)
load("@rules_foreign_cc//tools/build_defs:detect_root.bzl", "detect_root", "filter_containing_dirs_from_inputs")
load(
    "@rules_foreign_cc//tools/build_defs:run_shell_file_utils.bzl",
    "copy_directory",
    "fictive_file_in_genroot",
)
load(
    "@rules_foreign_cc//tools/build_defs:shell_script_helper.bzl",
    "convert_shell_script",
    "create_function",
    "os_name",
)

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
    "tools_deps": attr.label_list(mandatory = False, allow_files = True, cfg = "host", default = []),
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
    "_is_debug": attr.label(
        default = "@foreign_cc_platform_utils//:compilation_mode",
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
    lib_name = attrs.lib_name or ctx.attr.name

    inputs = _define_inputs(attrs)
    outputs = _define_outputs(ctx, attrs, lib_name)
    out_cc_info = _define_out_cc_info(ctx, attrs, inputs, outputs)

    cc_env = _correct_path_variable(get_env_vars(ctx))
    set_cc_envs = ""
    execution_os_name = os_name(ctx)
    if execution_os_name != "osx":
        set_cc_envs = "\n".join(["export {}=\"{}\"".format(key, cc_env[key]) for key in cc_env])

    version_and_lib = "Bazel external C/C++ Rules #{}. Building library '{}'\\n".format(VERSION, lib_name)

    # We can not declare outputs of the action, which are in parent-child relashion,
    # so we need to have a (symlinked) copy of the output directory to provide
    # both the C/C++ artifacts - libraries, headers, and binaries,
    # and the install directory as a whole (which is mostly nessesary for chained external builds).
    #
    # We want the install directory output of this rule to have the same name as the library,
    # so symlink it under the same name but in a subdirectory
    installdir_copy = copy_directory(ctx.actions, "$$INSTALLDIR$$", "copy_{}/{}".format(lib_name, lib_name))

    # we need this fictive file in the root to get the path of the root in the script
    empty = fictive_file_in_genroot(ctx.actions, ctx.label.name)

    define_variables = [
        set_cc_envs,
        "export EXT_BUILD_ROOT=##pwd##",
        "export BUILD_TMPDIR=##tmpdir##",
        "export EXT_BUILD_DEPS=##tmpdir##",
        "export INSTALLDIR=$$EXT_BUILD_ROOT$$/" + empty.file.dirname + "/" + lib_name,
    ]

    script_lines = [
        "##echo## \"\"",
        "##echo## \"{}\"".format(version_and_lib),
        "##echo## \"\"",
        "##script_prelude##",
        "\n".join(define_variables),
        "##path## $$EXT_BUILD_ROOT$$",
        "##mkdirs## $$INSTALLDIR$$",
        _print_env(),
        "\n".join(_copy_deps_and_tools(inputs)),
        "cd $$BUILD_TMPDIR$$",
        attrs.create_configure_script(ConfigureParameters(ctx = ctx, attrs = attrs, inputs = inputs)),
        "\n".join(attrs.make_commands),
        attrs.postfix_script or "",
        # replace references to the root directory when building ($BUILD_TMPDIR)
        # and the root where the dependencies were installed ($EXT_BUILD_DEPS)
        # for the results which are in $INSTALLDIR (with placeholder)
        "##replace_absolute_paths## $$INSTALLDIR$$ $$BUILD_TMPDIR$$",
        "##replace_absolute_paths## $$INSTALLDIR$$ $$EXT_BUILD_DEPS$$",
        installdir_copy.script,
        empty.script,
        "cd $$EXT_BUILD_ROOT$$",
    ]

    script_text = "#!/usr/bin/env bash\n" + convert_shell_script(ctx, script_lines)
    wrapped_outputs = wrap_outputs(ctx, lib_name, attrs.configure_name, script_text)

    rule_outputs = outputs.declared_outputs + [installdir_copy.file]

    execution_requirements = {"block-network": ""}
    if "requires-network" in ctx.attr.tags:
        execution_requirements = {"requires-network": ""}

    ctx.actions.run_shell(
        mnemonic = "Cc" + attrs.configure_name.capitalize() + "MakeRule",
        inputs = depset(inputs.declared_inputs, transitive = [ctx.attr._cc_toolchain.files]),
        outputs = rule_outputs + [
            empty.file,
            wrapped_outputs.log_file,
        ],
        tools = [wrapped_outputs.script_file],
        # We should take the default PATH passed by Bazel, not that from cc_toolchain
        # for Windows, because the PATH under msys2 is different and that is which we need
        # for shell commands
        use_default_shell_env = execution_os_name != "osx",
        command = wrapped_outputs.wrapper_script,
        execution_requirements = execution_requirements,
        # this is ignored if use_default_shell_env = True
        env = cc_env,
    )

    externally_built = ForeignCcArtifact(
        gen_dir = installdir_copy.file,
        bin_dir_name = attrs.out_bin_dir,
        lib_dir_name = attrs.out_lib_dir,
        include_dir_name = attrs.out_include_dir,
    )
    output_groups = _declare_output_groups(installdir_copy.file, outputs.out_binary_files)
    wrapped_files = [
        wrapped_outputs.script_file,
        wrapped_outputs.log_file,
        wrapped_outputs.wrapper_script_file,
    ]
    output_groups[attrs.configure_name + "_logs"] = wrapped_files
    return [
        DefaultInfo(files = depset(direct = rule_outputs + wrapped_files)),
        OutputGroupInfo(**output_groups),
        ForeignCcDeps(artifacts = depset(
            [externally_built],
            transitive = _get_transitive_artifacts(attrs.deps),
        )),
        CcInfo(
            compilation_context = out_cc_info.compilation_context,
            linking_context = out_cc_info.linking_context,
        ),
    ]

WrappedOutputs = provider(
    doc = "Structure for passing the log and scripts file information, and wrapper script text.",
    fields = {
        "script_file": "Main script file",
        "log_file": "Execution log file",
        "wrapper_script_file": "Wrapper script file (output for debugging purposes)",
        "wrapper_script": "Wrapper script text to execute",
    },
)

def wrap_outputs(ctx, lib_name, configure_name, script_text):
    build_script_file = ctx.actions.declare_file("{}/logs/{}_script.sh".format(lib_name, configure_name))
    ctx.actions.write(
        output = build_script_file,
        content = script_text,
        is_executable = True,
    )
    build_log_file = ctx.actions.declare_file("{}/logs/{}.log".format(lib_name, configure_name))

    cleanup_on_success_function = create_function(
        ctx,
        "cleanup_on_success",
        """##echo## \"rules_foreign_cc: Cleaning temp directories\"
rm -rf $BUILD_TMPDIR $EXT_BUILD_DEPS""",
    )
    cleanup_on_failure_function = create_function(
        ctx,
        "cleanup_on_failure",
        """##echo## "\\nrules_foreign_cc: Build failed!\
\\nrules_foreign_cc: Keeping temp build directory $$BUILD_TMPDIR$$ and dependencies directory\
 $$EXT_BUILD_DEPS$$ for debug.\\nrules_foreign_cc:\
 Please note that the directories inside a sandbox are still\
 cleaned unless you specify '--sandbox_debug' Bazel command line flag.\\n\\n\
rules_foreign_cc: Printing build logs:\\n\\n_____ BEGIN BUILD LOGS _____\\n"
##cat## $$BUILD_LOG$$
##echo## "\\n_____ END BUILD LOGS _____\\n"
##echo## "Printing build script:\\n\\n_____ BEGIN BUILD SCRIPT _____\\n"
##cat## $$BUILD_SCRIPT$$
##echo## "\\n_____ END BUILD SCRIPT _____\\n"
##echo## "rules_foreign_cc: Build script location: $$BUILD_SCRIPT$$\\n"
##echo## "rules_foreign_cc: Build log location: $$BUILD_LOG$$\\n\\n"
""",
    )
    trap_function = "##cleanup_function## cleanup_on_success cleanup_on_failure"

    build_command_lines = [
        "##assert_script_errors##",
        cleanup_on_success_function,
        cleanup_on_failure_function,
        # the call trap is defined inside, in a way how the shell function should be called
        # see, for instance, linux_commands.bzl
        trap_function,
        "export BUILD_SCRIPT=\"{}\"".format(build_script_file.path),
        "export BUILD_LOG=\"{}\"".format(build_log_file.path),
        # sometimes the log file is not created, we do not want our script to fail because of this
        "##touch## $$BUILD_LOG$$",
        "##redirect_out_err## $$BUILD_SCRIPT$$ $$BUILD_LOG$$",
    ]
    build_command = "#!/usr/bin/env bash\n" + convert_shell_script(ctx, build_command_lines)

    wrapper_script_file = ctx.actions.declare_file("{}/logs/wrapper_script.sh".format(lib_name))
    ctx.actions.write(
        output = wrapper_script_file,
        content = build_command,
    )

    return WrappedOutputs(
        script_file = build_script_file,
        log_file = build_log_file,
        wrapper_script_file = wrapper_script_file,
        wrapper_script = build_command,
    )

def _declare_output_groups(installdir, outputs):
    dict_ = {}
    dict_["gen_dir"] = depset([installdir])
    for output in outputs:
        dict_[output.basename] = [output]
    return dict_

def _get_transitive_artifacts(deps):
    artifacts = []
    for dep in deps:
        foreign_dep = get_foreign_cc_dep(dep)
        if foreign_dep:
            artifacts.append(foreign_dep.artifacts)
    return artifacts

def _print_env():
    return "\n".join([
        "##echo## \"Environment:______________\\n\"",
        "##env##",
        "##echo## \"__________________________\\n\"",
    ])

def _correct_path_variable(env):
    value = env.get("PATH", "")
    if not value:
        return env
    value = env.get("PATH", "").replace("C:\\", "/c/")
    value = value.replace("\\", "/")
    value = value.replace(";", ":")
    env["PATH"] = "$PATH:" + value
    return env

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
    lines += _symlink_contents_to_dir("lib", files.libs)
    lines += _symlink_contents_to_dir("include", files.headers + files.include_dirs)

    if files.tools_files:
        lines.append("##mkdirs## $$EXT_BUILD_DEPS$$/bin")
    for tool in files.tools_files:
        lines.append("##symlink_to_dir## $$EXT_BUILD_ROOT$$/{} $$EXT_BUILD_DEPS$$/bin/".format(tool))

    for ext_dir in files.ext_build_dirs:
        lines.append("##symlink_to_dir## $$EXT_BUILD_ROOT$$/{} $$EXT_BUILD_DEPS$$".format(_file_path(ext_dir)))

    lines.append("##children_to_path## $$EXT_BUILD_DEPS$$/bin")
    lines.append("##path## $$EXT_BUILD_DEPS$$/bin")

    return lines

def _symlink_contents_to_dir(dir_name, files_list):
    # It is possible that some duplicate libraries will be passed as inputs
    # to cmake_external or configure_make. Filter duplicates out here.
    files_list = collections.uniq(files_list)
    if len(files_list) == 0:
        return []
    lines = ["##mkdirs## $$EXT_BUILD_DEPS$$/" + dir_name]

    for file in files_list:
        path = _file_path(file).strip()
        if path:
            lines.append("##symlink_contents_to_dir## \
$$EXT_BUILD_ROOT$$/{} $$EXT_BUILD_DEPS$$/{}".format(path, dir_name))

    return lines

def _file_path(file):
    return file if type(file) == "string" else file.path

_FORBIDDEN_FOR_FILENAME = ["\\", "/", ":", "*", "\"", "<", ">", "|"]

def _check_file_name(var):
    if (len(var) == 0):
        fail("Library name cannot be an empty string.")
    for index in range(0, len(var) - 1):
        letter = var[index]
        if letter in _FORBIDDEN_FOR_FILENAME:
            fail("Symbol '%s' is forbidden in library name '%s'." % (letter, var))

_Outputs = provider(
    doc = "Provider to keep different kinds of the external build output files and directories",
    fields = dict(
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

    _check_file_name(lib_name)

    out_include_dir = ctx.actions.declare_directory(lib_name + "/" + attrs.out_include_dir)

    out_binary_files = _declare_out(ctx, lib_name, attrs.out_bin_dir, attrs.binaries)

    libraries = LibrariesToLinkInfo(
        static_libraries = _declare_out(ctx, lib_name, attrs.out_lib_dir, static_libraries),
        shared_libraries = _declare_out(ctx, lib_name, attrs.out_lib_dir, attrs.shared_libraries),
        interface_libraries = _declare_out(ctx, lib_name, attrs.out_lib_dir, attrs.interface_libraries),
    )
    declared_outputs = [out_include_dir] + out_binary_files
    declared_outputs += libraries.static_libraries
    declared_outputs += libraries.shared_libraries + libraries.interface_libraries

    return _Outputs(
        out_include_dir = out_include_dir,
        out_binary_files = out_binary_files,
        libraries = libraries,
        declared_outputs = declared_outputs,
    )

def _declare_out(ctx, lib_name, dir_, files):
    if files and len(files) > 0:
        return [ctx.actions.declare_file("/".join([lib_name, dir_, file])) for file in files]
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
    cc_infos = []

    bazel_headers = []
    bazel_system_includes = []
    bazel_libs = []

    # This framework function-built libraries: copy result directories under
    # $EXT_BUILD_DEPS/lib-name
    ext_build_dirs = []

    for dep in attrs.deps:
        external_deps = get_foreign_cc_dep(dep)

        cc_infos.append(dep[CcInfo])

        if external_deps:
            ext_build_dirs += [artifact.gen_dir for artifact in external_deps.artifacts.to_list()]
        else:
            headers_info = _get_headers(dep[CcInfo].compilation_context)
            bazel_headers += headers_info.headers
            bazel_system_includes += headers_info.include_dirs
            bazel_libs += _collect_libs(dep[CcInfo].linking_context)

    # Keep the order of the transitive foreign dependencies
    # (the order is important for the correct linking),
    # but filter out repeating directories
    ext_build_dirs = uniq_list_keep_order(ext_build_dirs)

    tools_roots = []
    tools_files = []
    for tool in attrs.tools_deps:
        tool_root = detect_root(tool)
        tools_roots.append(tool_root)
        for file_list in tool.files.to_list():
            tools_files += _list(file_list)

    for tool in attrs.additional_tools:
        for file_list in tool.files:
            tools_files += _list(file_list)

    # These variables are needed for correct C/C++ providers constraction,
    # they should contain all libraries and include directories.
    cc_info_merged = cc_common.merge_cc_infos(cc_infos = cc_infos)

    return InputFiles(
        headers = bazel_headers,
        include_dirs = bazel_system_includes,
        libs = bazel_libs,
        tools_files = tools_roots,
        deps_compilation_info = cc_info_merged.compilation_context,
        deps_linking_info = cc_info_merged.linking_context,
        ext_build_dirs = ext_build_dirs,
        declared_inputs = filter_containing_dirs_from_inputs(attrs.lib_source.files.to_list()) +
                          bazel_libs +
                          tools_files +
                          attrs.additional_inputs +
                          cc_info_merged.compilation_context.headers.to_list() +
                          ext_build_dirs,
    )

def uniq_list_keep_order(list):
    result = []
    contains_map = {}
    for item in list:
        if contains_map.get(item):
            continue
        contains_map[item] = 1
        result.append(item)
    return result

def get_foreign_cc_dep(dep):
    return dep[ForeignCcDeps] if ForeignCcDeps in dep else None

# consider optimization here to do not iterate both collections
def _get_headers(compilation_info):
    include_dirs = compilation_info.system_includes.to_list() + \
                   compilation_info.includes.to_list()

    # do not use quote includes, currently they do not contain
    # library-specific information
    include_dirs = collections.uniq(include_dirs)
    headers = []
    for header in compilation_info.headers.to_list():
        path = header.path
        included = False
        for dir_ in include_dirs:
            if path.startswith(dir_):
                included = True
                break
        if not included:
            headers.append(header)
    return struct(
        headers = headers,
        include_dirs = include_dirs,
    )

def _define_out_cc_info(ctx, attrs, inputs, outputs):
    compilation_info = cc_common.create_compilation_context(
        headers = depset([outputs.out_include_dir]),
        system_includes = depset([outputs.out_include_dir.path]),
        includes = depset([]),
        quote_includes = depset([]),
        defines = depset(attrs.defines),
    )
    linking_info = create_linking_info(ctx, attrs.linkopts, outputs.libraries)
    cc_info = CcInfo(
        compilation_context = compilation_info,
        linking_context = linking_info,
    )
    inputs_info = CcInfo(
        compilation_context = inputs.deps_compilation_info,
        linking_context = inputs.deps_linking_info,
    )

    return cc_common.merge_cc_infos(cc_infos = [cc_info, inputs_info])

def _extract_libraries(library_to_link):
    return [
        library_to_link.static_library,
        library_to_link.pic_static_library,
        library_to_link.dynamic_library,
        library_to_link.interface_library,
    ]

def _collect_libs(cc_linking):
    libs = []
    libraries_to_link = cc_linking.libraries_to_link
    if type(libraries_to_link) == "depset":
        libraries_to_link = libraries_to_link.to_list()

    for library_to_link in libraries_to_link:
        for library in _extract_libraries(library_to_link):
            if library:
                libs.append(library)
    return collections.uniq(libs)
