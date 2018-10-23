""" Defines create_linking_info, which wraps passed libraries into CcLinkingInfo
"""

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load(
    "@bazel_tools//tools/build_defs/cc:action_names.bzl",
    "ASSEMBLE_ACTION_NAME",
    "CPP_COMPILE_ACTION_NAME",
    "CPP_LINK_DYNAMIC_LIBRARY_ACTION_NAME",
    "CPP_LINK_EXECUTABLE_ACTION_NAME",
    "CPP_LINK_STATIC_LIBRARY_ACTION_NAME",
    "C_COMPILE_ACTION_NAME",
)

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

def _to_list(element):
    if element == None:
        return []
    else:
        return [element]

def _to_depset(element):
    if element == None:
        return depset()
    return depset(element)

def _perform_error_checks(
        system_provided,
        shared_library_artifacts,
        interface_library_artifacts,
        targets_windows):
    # If the shared library will be provided by system during runtime, users are not supposed to
    # specify shared_library.
    if system_provided and shared_library_artifacts:
        fail("'shared_library' shouldn't be specified when 'system_provided' is true")

    # If a shared library won't be provided by system during runtime and we are linking the shared
    # library through interface library, the shared library must be specified.
    if (not system_provided and not shared_library_artifacts and
        interface_library_artifacts):
        fail("'shared_library' should be specified when 'system_provided' is false")

    if targets_windows and shared_library_artifacts:
        fail("'interface library' must be specified when using cc_import for " +
             "shared library on Windows")

def _build_static_library_to_link(ctx, library):
    if library == None:
        fail("Parameter 'static_library_artifact' cannot be None")

    static_library_category = None
    if ctx.attr.alwayslink:
        static_library_category = "alwayslink_static_library"
    else:
        static_library_category = "static_library"

    return cc_common.create_library_to_link(
        ctx = ctx,
        library = library,
        artifact_category = static_library_category,
    )

def _build_shared_library_to_link(ctx, library, cc_toolchain, targets_windows):
    if library == None:
        fail("Parameter 'shared_library_artifact' cannot be None")

    if not targets_windows and hasattr(cc_common, "create_symlink_library_to_link"):
        return cc_common.create_symlink_library_to_link(
            ctx = ctx,
            cc_toolchain = cc_toolchain,
            library = library,
        )

    return cc_common.create_library_to_link(
        ctx = ctx,
        library = library,
        artifact_category = "dynamic_library",
    )

def _build_interface_library_to_link(ctx, library, cc_toolchain, targets_windows):
    if library == None:
        fail("Parameter 'interface_library_artifact' cannot be None")

    if not targets_windows and hasattr(cc_common, "create_symlink_library_to_link"):
        return cc_common.create_symlink_library_to_link(
            ctx = ctx,
            cc_toolchain = cc_toolchain,
            library = library,
        )
    return cc_common.create_library_to_link(
        ctx = ctx,
        library = library,
        artifact_category = "interface_library",
    )

# we could possibly take a decision about linking interface/shared library beased on each library name
# (usefull for the case when multiple output targets are provided)
def _build_libraries_to_link_and_runtime_artifact(ctx, files, cc_toolchain, targets_windows):
    static_libraries = [_build_static_library_to_link(ctx, lib) for lib in (files.static_libraries or [])]

    shared_libraries = []
    runtime_artifacts = []
    if files.shared_libraries != None:
        for lib in files.shared_libraries:
            shared_library = _build_shared_library_to_link(ctx, lib, cc_toolchain, targets_windows)
            shared_libraries += [shared_library]
            runtime_artifacts += [shared_library.artifact()]

    interface_libraries = []
    if files.interface_libraries != None:
        for lib in files.interface_libraries:
            interface_libraries += [_build_interface_library_to_link(ctx, lib, cc_toolchain, targets_windows)]

    dynamic_libraries_for_linking = None
    if len(interface_libraries) > 0:
        dynamic_libraries_for_linking = interface_libraries
    else:
        dynamic_libraries_for_linking = shared_libraries

    return {
        "static_libraries": static_libraries,
        "dynamic_libraries": dynamic_libraries_for_linking,
        "runtime_artifacts": runtime_artifacts,
    }

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
        "static_mode_params_for_dynamic_library": static_shared,
        "static_mode_params_for_executable": static_no_shared,
        "dynamic_mode_params_for_dynamic_library": no_static_shared,
        "dynamic_mode_params_for_executable": no_static_no_shared,
    }

def targets_windows(ctx, cc_toolchain):
    """ Returns true if build is targeting Windows
    Args:
        ctx - rule context
        cc_toolchain - optional - Cc toolchain
    """
    toolchain = cc_toolchain if cc_toolchain else find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        cc_toolchain = toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    return cc_common.is_enabled(
        feature_configuration = feature_configuration,
        feature_name = "targets_windows",
    )

def create_linking_info(ctx, user_link_flags, files):
    """ Creates CcLinkingInfo for the passed user link options and libraries.
    Args:
        ctx - rule context
        user_link_flags - (list of strings) link optins, provided by user
        files - (LibrariesToLink) provider with the library files
    """
    cc_toolchain = find_cpp_toolchain(ctx)
    for_windows = targets_windows(ctx, cc_toolchain)

    _perform_error_checks(
        False,
        files.shared_libraries,
        files.interface_libraries,
        for_windows,
    )

    artifacts = _build_libraries_to_link_and_runtime_artifact(
        ctx,
        files,
        cc_toolchain,
        for_windows,
    )

    link_params = _build_cc_link_params(ctx, user_link_flags, **artifacts)

    return CcLinkingInfo(**link_params)

def get_env_vars(ctx):
    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    copts = ctx.attr.copts if hasattr(ctx.attr, "copts") else depset()

    vars = dict()

    for action_name in [C_COMPILE_ACTION_NAME, CPP_LINK_STATIC_LIBRARY_ACTION_NAME, CPP_LINK_EXECUTABLE_ACTION_NAME]:
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
    # see workspace_definitions.bzl
    return str(True) == ctx.attr._is_debug[config_common.FeatureFlagInfo].value

def get_tools_info(ctx):
    """ Takes information about tools paths from cc_toolchain, returns CxxToolsInfo
    Args:
        ctx - rule context
    """
    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    return CxxToolsInfo(
        cc = cc_common.get_tool_for_action(
            feature_configuration = feature_configuration,
            action_name = C_COMPILE_ACTION_NAME,
        ),
        cxx = cc_common.get_tool_for_action(
            feature_configuration = feature_configuration,
            action_name = CPP_COMPILE_ACTION_NAME,
        ),
        cxx_linker_static = cc_common.get_tool_for_action(
            feature_configuration = feature_configuration,
            action_name = CPP_LINK_STATIC_LIBRARY_ACTION_NAME,
        ),
        cxx_linker_executable = cc_common.get_tool_for_action(
            feature_configuration = feature_configuration,
            action_name = CPP_LINK_EXECUTABLE_ACTION_NAME,
        ),
    )

def get_flags_info(ctx):
    """ Takes information about flags from cc_toolchain, returns CxxFlagsInfo
    Args:
        ctx - rule context
    """
    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    copts = ctx.attr.copts if hasattr(ctx.attr, "copts") else depset()

    return CxxFlagsInfo(
        cc = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = C_COMPILE_ACTION_NAME,
            variables = cc_common.create_compile_variables(
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain,
                user_compile_flags = copts,
            ),
        ),
        cxx = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = CPP_COMPILE_ACTION_NAME,
            variables = cc_common.create_compile_variables(
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain,
                user_compile_flags = copts,
                add_legacy_cxx_options = True,
            ),
        ),
        cxx_linker_shared = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = CPP_LINK_DYNAMIC_LIBRARY_ACTION_NAME,
            variables = cc_common.create_link_variables(
                cc_toolchain = cc_toolchain,
                feature_configuration = feature_configuration,
                is_using_linker = True,
                is_linking_dynamic_library = True,
            ),
        ),
        cxx_linker_static = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = CPP_LINK_STATIC_LIBRARY_ACTION_NAME,
            variables = cc_common.create_link_variables(
                cc_toolchain = cc_toolchain,
                feature_configuration = feature_configuration,
                is_using_linker = False,
                is_linking_dynamic_library = False,
            ),
        ),
        cxx_linker_executable = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = CPP_LINK_EXECUTABLE_ACTION_NAME,
            variables = cc_common.create_link_variables(
                cc_toolchain = cc_toolchain,
                feature_configuration = feature_configuration,
                is_using_linker = True,
                is_linking_dynamic_library = False,
            ),
        ),
        assemble = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = ASSEMBLE_ACTION_NAME,
            variables = cc_common.create_compile_variables(
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain,
                user_compile_flags = copts,
            ),
        ),
    )

def absolutize_path_in_str(workspace_name, root_str, text):
    """ Replaces relative paths in [the middle of] 'text', prepending them with 'root_str'.
    If there is nothing to replace, returns the 'text'.

    We only will replace relative paths starting with either 'external/' or '<top-package-name>/',
    because we only want to point with absolute paths to external repositories or inside our
    current workspace. (And also to limit the possibility of error with such not exact replacing.)

    Args:
        workspace_name - workspace name
        text - the text to do replacement in
        root_str - the text to prepend to the found relative path
    """
    new_text = _prefix(text, "external/", root_str)
    if new_text == text:
        new_text = _prefix(text, workspace_name + "/", root_str)

    return new_text

def _prefix(text, from_str, prefix):
    text = text.replace('"', '\\"')
    (before, middle, after) = text.partition(from_str)
    if not middle or before.endswith("/"):
        return text
    return before + prefix + middle + after
