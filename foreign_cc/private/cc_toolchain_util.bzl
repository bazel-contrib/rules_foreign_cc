""" Defines create_linking_info, which wraps passed libraries into CcLinkingInfo
"""

load("@bazel_skylib//lib:collections.bzl", "collections")
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

LibrariesToLinkInfo = provider(
    doc = "Libraries to be wrapped into CcLinkingInfo",
    fields = dict(
        static_libraries = "Static library files, optional",
        shared_libraries = "Shared library files, optional",
        interface_libraries = "Interface library files, optional",
    ),
)

CxxToolsInfo = provider(
    doc = "Paths to the C/C++ tools, taken from the toolchain",
    fields = dict(
        cc = "C compiler",
        cxx = "C++ compiler",
        cxx_linker_static = "C++ linker to link static library",
        cxx_linker_executable = "C++ linker to link executable",
    ),
)

CxxFlagsInfo = provider(
    doc = "Flags for the C/C++ tools, taken from the toolchain",
    fields = dict(
        cc = "C compiler flags",
        cxx = "C++ compiler flags",
        cxx_linker_shared = "C++ linker flags when linking shared library",
        cxx_linker_static = "C++ linker flags when linking static library",
        cxx_linker_executable = "C++ linker flags when linking executable",
        assemble = "Assemble flags",
    ),
)

# Since we're calling an external build system we can't support some
# features that may be enabled on the toolchain - so we disable
# them here when configuring the toolchain flags to pass to the external
# build system.
FOREIGN_CC_DISABLED_FEATURES = [
    "layering_check",
    "module_maps",
    "thin_lto",
]

def _to_list(element):
    if element == None:
        return []
    else:
        return [element]

def _to_depset(element):
    if element == None:
        return depset()
    return depset(element)

def _configure_features(ctx, cc_toolchain):
    return cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features + FOREIGN_CC_DISABLED_FEATURES,
    )

def _create_libraries_to_link(ctx, files):
    libs = []

    static_map = _files_map(_filter(files.static_libraries or [], _is_position_independent, True))
    pic_static_map = _files_map(_filter(files.static_libraries or [], _is_position_independent, False))
    shared_map = _files_map(files.shared_libraries or [])
    interface_map = _files_map(files.interface_libraries or [])

    names = collections.uniq(static_map.keys() + pic_static_map.keys() + shared_map.keys() + interface_map.keys())

    cc_toolchain = find_cpp_toolchain(ctx)

    feature_configuration = _configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
    )

    for name_ in names:
        libs.append(cc_common.create_library_to_link(
            actions = ctx.actions,
            feature_configuration = feature_configuration,
            cc_toolchain = cc_toolchain,
            static_library = static_map.get(name_),
            pic_static_library = pic_static_map.get(name_),
            dynamic_library = shared_map.get(name_),
            interface_library = interface_map.get(name_),
            alwayslink = ctx.attr.alwayslink,
        ))

    return depset(direct = libs)

def _is_position_independent(file):
    return file.basename.endswith(".pic.a")

def _filter(list_, predicate, inverse):
    result = []
    for elem in list_:
        check = predicate(elem)
        if not inverse and check or inverse and not check:
            result.append(elem)
    return result

def _files_map(files_list):
    by_names_map = {}
    for file_ in files_list:
        name_ = _file_name_no_ext(file_.basename)
        value = by_names_map.get(name_)
        if value:
            fail("Can not have libraries with the same name in the same category")
        by_names_map[name_] = file_
    return by_names_map

def _defines_from_deps(ctx):
    return depset(transitive = [dep[CcInfo].compilation_context.defines for dep in getattr(ctx.attr, "deps", [])])

def _build_cc_link_params(
        ctx,
        user_link_flags,
        static_libraries,
        dynamic_libraries,
        runtime_artifacts):
    static_shared = None
    static_no_shared = None
    if static_libraries != None and len(static_libraries) > 0:
        static_shared = cc_common.create_cc_link_params(
            ctx = ctx,
            user_link_flags = user_link_flags,
            libraries_to_link = _to_depset(static_libraries),
        )
        static_no_shared = cc_common.create_cc_link_params(
            ctx = ctx,
            libraries_to_link = _to_depset(static_libraries),
        )
    else:
        static_shared = cc_common.create_cc_link_params(
            ctx = ctx,
            user_link_flags = user_link_flags,
            libraries_to_link = _to_depset(dynamic_libraries),
            dynamic_libraries_for_runtime = _to_depset(runtime_artifacts),
        )
        static_no_shared = cc_common.create_cc_link_params(
            ctx = ctx,
            libraries_to_link = _to_depset(dynamic_libraries),
            dynamic_libraries_for_runtime = _to_depset(runtime_artifacts),
        )

    no_static_shared = None
    no_static_no_shared = None
    if dynamic_libraries != None and len(dynamic_libraries) > 0:
        no_static_shared = cc_common.create_cc_link_params(
            ctx = ctx,
            user_link_flags = user_link_flags,
            libraries_to_link = _to_depset(dynamic_libraries),
            dynamic_libraries_for_runtime = _to_depset(runtime_artifacts),
        )
        no_static_no_shared = cc_common.create_cc_link_params(
            ctx = ctx,
            libraries_to_link = _to_depset(dynamic_libraries),
            dynamic_libraries_for_runtime = _to_depset(runtime_artifacts),
        )
    else:
        no_static_shared = cc_common.create_cc_link_params(
            ctx = ctx,
            user_link_flags = user_link_flags,
            libraries_to_link = _to_depset(static_libraries),
        )
        no_static_no_shared = cc_common.create_cc_link_params(
            ctx = ctx,
            libraries_to_link = _to_depset(static_libraries),
        )

    return {
        "dynamic_mode_params_for_dynamic_library": no_static_shared,
        "dynamic_mode_params_for_executable": no_static_no_shared,
        "static_mode_params_for_dynamic_library": static_shared,
        "static_mode_params_for_executable": static_no_shared,
    }

def targets_windows(ctx, cc_toolchain):
    """Returns true if build is targeting Windows

    Args:
        ctx: rule context
        cc_toolchain: optional - Cc toolchain
    """
    toolchain = cc_toolchain if cc_toolchain else find_cpp_toolchain(ctx)
    feature_configuration = _configure_features(
        ctx = ctx,
        cc_toolchain = toolchain,
    )

    return cc_common.is_enabled(
        feature_configuration = feature_configuration,
        feature_name = "targets_windows",
    )

def create_linking_info(ctx, user_link_flags, files):
    """Creates CcLinkingInfo for the passed user link options and libraries.

    Args:
        ctx (ctx): rule context
        user_link_flags (list of strings): link optins, provided by user
        files (LibrariesToLink): provider with the library files
    """

    return cc_common.create_linking_context(
        linker_inputs = depset(direct = [
            cc_common.create_linker_input(
                owner = ctx.label,
                libraries = _create_libraries_to_link(ctx, files),
                user_link_flags = depset(direct = user_link_flags),
            ),
        ]),
    )

# buildifier: disable=function-docstring
def get_env_vars(ctx):
    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = _configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
    )
    copts = getattr(ctx.attr, "copts", [])

    action_names = [
        ACTION_NAMES.c_compile,
        ACTION_NAMES.cpp_link_static_library,
        ACTION_NAMES.cpp_link_executable,
    ]

    vars = dict()
    for action_name in action_names:
        vars.update(cc_common.get_environment_variables(
            feature_configuration = feature_configuration,
            action_name = action_name,
            variables = cc_common.create_compile_variables(
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain,
                user_compile_flags = copts,
            ),
        ))
    return vars

def is_debug_mode(ctx):
    # Compilation mode currently defaults to fastbuild. Use that if for some reason the variable is not set
    # https://docs.bazel.build/versions/master/command-line-reference.html#flag--compilation_mode
    return ctx.var.get("COMPILATION_MODE", "fastbuild") == "dbg"

def get_tools_info(ctx):
    """Takes information about tools paths from cc_toolchain, returns CxxToolsInfo

    Args:
        ctx: rule context
    """
    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = _configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
    )

    return CxxToolsInfo(
        cc = cc_common.get_tool_for_action(
            feature_configuration = feature_configuration,
            action_name = ACTION_NAMES.c_compile,
        ),
        cxx = cc_common.get_tool_for_action(
            feature_configuration = feature_configuration,
            action_name = ACTION_NAMES.cpp_compile,
        ),
        cxx_linker_static = cc_common.get_tool_for_action(
            feature_configuration = feature_configuration,
            action_name = ACTION_NAMES.cpp_link_static_library,
        ),
        cxx_linker_executable = cc_common.get_tool_for_action(
            feature_configuration = feature_configuration,
            action_name = ACTION_NAMES.cpp_link_executable,
        ),
    )

def get_flags_info(ctx, link_output_file = None):
    """Takes information about flags from cc_toolchain, returns CxxFlagsInfo

    Args:
        ctx: rule context
        link_output_file: output file to be specified in the link command line
            flags

    Returns:
        CxxFlagsInfo: A provider containing Cxx flags
    """
    cc_toolchain_ = find_cpp_toolchain(ctx)
    feature_configuration = _configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain_,
    )

    copts = (ctx.fragments.cpp.copts + ctx.fragments.cpp.conlyopts + getattr(ctx.attr, "copts", [])) or []
    cxxopts = (ctx.fragments.cpp.copts + ctx.fragments.cpp.cxxopts + getattr(ctx.attr, "copts", [])) or []
    linkopts = (ctx.fragments.cpp.linkopts + getattr(ctx.attr, "linkopts", [])) or []
    defines = _defines_from_deps(ctx)

    flags = CxxFlagsInfo(
        cc = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = ACTION_NAMES.c_compile,
            variables = cc_common.create_compile_variables(
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain_,
                preprocessor_defines = defines,
            ),
        ),
        cxx = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = ACTION_NAMES.cpp_compile,
            variables = cc_common.create_compile_variables(
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain_,
                preprocessor_defines = defines,
                add_legacy_cxx_options = True,
            ),
        ),
        cxx_linker_shared = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = ACTION_NAMES.cpp_link_dynamic_library,
            variables = cc_common.create_link_variables(
                cc_toolchain = cc_toolchain_,
                feature_configuration = feature_configuration,
                is_using_linker = True,
                is_linking_dynamic_library = True,
            ),
        ),
        cxx_linker_static = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = ACTION_NAMES.cpp_link_static_library,
            variables = cc_common.create_link_variables(
                cc_toolchain = cc_toolchain_,
                feature_configuration = feature_configuration,
                is_using_linker = False,
                is_linking_dynamic_library = False,
                output_file = link_output_file,
            ),
        ),
        cxx_linker_executable = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = ACTION_NAMES.cpp_link_executable,
            variables = cc_common.create_link_variables(
                cc_toolchain = cc_toolchain_,
                feature_configuration = feature_configuration,
                is_using_linker = True,
                is_linking_dynamic_library = False,
            ),
        ),
        assemble = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = ACTION_NAMES.assemble,
            variables = cc_common.create_compile_variables(
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain_,
                preprocessor_defines = defines,
            ),
        ),
    )
    return CxxFlagsInfo(
        cc = _convert_flags(cc_toolchain_.compiler, _add_if_needed(flags.cc, copts)),
        cxx = _convert_flags(cc_toolchain_.compiler, _add_if_needed(flags.cxx, cxxopts)),
        cxx_linker_shared = _convert_flags(cc_toolchain_.compiler, _add_if_needed(flags.cxx_linker_shared, linkopts)),
        cxx_linker_static = _convert_flags(cc_toolchain_.compiler, flags.cxx_linker_static),
        cxx_linker_executable = _convert_flags(cc_toolchain_.compiler, _add_if_needed(flags.cxx_linker_executable, linkopts)),
        assemble = _convert_flags(cc_toolchain_.compiler, _add_if_needed(flags.assemble, copts)),
    )

def _convert_flags(compiler, flags):
    """ Rewrites flags depending on the provided compiler.

    MSYS2 may convert leading slashes to the absolute path of the msys root directory, even if MSYS_NO_PATHCONV=1 and MSYS2_ARG_CONV_EXCL="*"
    .E.g MSYS2 may convert "/nologo" to "C:/msys64/nologo".
    Therefore, as MSVC tool flags can start with either a slash or dash, convert slashes to dashes

    Args:
        compiler: The target compiler, e.g. gcc, msvc-cl, mingw-gcc
        flags: The flags to convert

    Returns:
        list: The converted flags
    """
    if compiler == "msvc-cl":
        return [flag.replace("/", "-") if flag.startswith("/") else flag for flag in flags]
    return flags

def _add_if_needed(arr, add_arr):
    filtered = []
    for to_add in add_arr:
        found = False
        for existing in arr:
            if existing == to_add:
                found = True
        if not found:
            filtered.append(to_add)
    return arr + filtered

def absolutize_path_in_str(workspace_name, root_str, text, force = False):
    """Replaces relative paths in [the middle of] 'text', prepending them with 'root_str'. If there is nothing to replace, returns the 'text'.

    We only will replace relative paths starting with either 'external/' or '<top-package-name>/',
    because we only want to point with absolute paths to external repositories or inside our
    current workspace. (And also to limit the possibility of error with such not exact replacing.)

    Args:
        workspace_name: workspace name
        text: the text to do replacement in
        root_str: the text to prepend to the found relative path
        force: If true, the `root_str` will always be prepended

    Returns:
        string: A formatted string
    """
    new_text = _prefix(text, "external/", root_str)
    if new_text == text:
        new_text = _prefix(text, workspace_name + "/", root_str)

    # Check to see if the text is already absolute on a unix and windows system
    is_already_absolute = text.startswith("/") or \
                          (len(text) > 2 and text[0].isalpha() and text[1] == ":")

    # absolutize relative by adding our working directory
    # this works because we ru on windows under msys now
    if force and new_text == text and not is_already_absolute:
        new_text = root_str + "/" + text

    return new_text

def _prefix(text, from_str, prefix):
    (before, middle, after) = text.partition(from_str)
    if not middle or before.endswith("/"):
        return text
    return before + prefix + middle + after

def _file_name_no_ext(basename):
    (before, separator, after) = basename.rpartition(".")
    return before
