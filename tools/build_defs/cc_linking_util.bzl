""" Defines create_linking_info, which wraps passed libraries into CcLinkingInfo
"""

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

LibrariesToLinkInfo = provider(
    doc = "Libraries to be wrapped into CcLinkingInfo",
    fields = dict(
     static_library = "Static library file, optional",
     shared_library = "Dynamic library file, optional",
     interface_library = "Interface library file, optional",
))

def _to_list(element):
    if element == None:
        return []
    else:
        return [element]

def _to_depset(element):
    if element == None:
        return depset()
    else:
        return depset([element])

def _perform_error_checks(
        system_provided,
        shared_library_artifact,
        interface_library_artifact,
        targets_windows):
    # If the shared library will be provided by system during runtime, users are not supposed to
    # specify shared_library.
    if system_provided and shared_library_artifact != None:
        fail("'shared_library' shouldn't be specified when 'system_provided' is true")

    # If a shared library won't be provided by system during runtime and we are linking the shared
    # library through interface library, the shared library must be specified.
    if (not system_provided and shared_library_artifact == None and
        interface_library_artifact != None):
        fail("'shared_library' should be specified when 'system_provided' is false")

    if targets_windows and shared_library_artifact != None:
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

    if targets_windows:
        return cc_common.create_library_to_link(
            ctx = ctx,
            library = library,
            artifact_category = "dynamic_library",
        )
    else:
        return cc_common.create_symlink_library_to_link(
            ctx = ctx,
            cc_toolchain = cc_toolchain,
            library = library,
        )

def _build_interface_library_to_link(ctx, library, cc_toolchain, targets_windows):
    if library == None:
        fail("Parameter 'interface_library_artifact' cannot be None")

    if targets_windows:
        return cc_common.create_library_to_link(
            ctx = ctx,
            library = library,
            artifact_category = "interface_library",
        )
    else:
        return cc_common.create_symlink_library_to_link(
            ctx = ctx,
            cc_toolchain = cc_toolchain,
            library = library,
        )

def _build_libraries_to_link_and_runtime_artifact(ctx, files, cc_toolchain, targets_windows):
    static_library = None
    if files.static_library != None:
        static_library = _build_static_library_to_link(ctx, files.static_library)

    shared_library = None
    runtime_artifact = None
    if files.shared_library != None:
        shared_library = _build_shared_library_to_link(ctx, files.shared_library, cc_toolchain, targets_windows)
        runtime_artifact = shared_library.artifact()

    interface_library = None
    if files.interface_library != None:
        interface_library = _build_interface_library_to_link(ctx, files.interface_library, cc_toolchain, targets_windows)

    dynamic_library_for_linking = None
    if interface_library != None:
        dynamic_library_for_linking = interface_library
    else:
        dynamic_library_for_linking = shared_library

    return {"static_library": static_library,
            "dynamic_library": dynamic_library_for_linking,
            "runtime_artifact": runtime_artifact}

def _build_cc_link_params(
        ctx,
        user_link_flags,
        static_library,
        dynamic_library,
        runtime_artifact):
    static_shared = None
    static_no_shared = None
    if static_library != None:
        static_shared = cc_common.create_cc_link_params(
            ctx = ctx,
            user_link_flags = user_link_flags,
            libraries_to_link = _to_depset(static_library),
        )
        static_no_shared = cc_common.create_cc_link_params(
            ctx = ctx,
            libraries_to_link = _to_depset(static_library),
        )
    else:
        static_shared = cc_common.create_cc_link_params(
            ctx = ctx,
            user_link_flags = user_link_flags,
            libraries_to_link = _to_depset(dynamic_library),
            dynamic_libraries_for_runtime = _to_depset(runtime_artifact),
        )
        static_no_shared = cc_common.create_cc_link_params(
            ctx = ctx,
            libraries_to_link = _to_depset(dynamic_library),
            dynamic_libraries_for_runtime = _to_depset(runtime_artifact),
        )

    no_static_shared = None
    no_static_no_shared = None
    if dynamic_library != None:
        no_static_shared = cc_common.create_cc_link_params(
            ctx = ctx,
            user_link_flags = user_link_flags,
            libraries_to_link = _to_depset(dynamic_library),
            dynamic_libraries_for_runtime = _to_depset(runtime_artifact),
        )
        no_static_no_shared = cc_common.create_cc_link_params(
            ctx = ctx,
            libraries_to_link = _to_depset(dynamic_library),
            dynamic_libraries_for_runtime = _to_depset(runtime_artifact),
        )
    else:
        no_static_shared = cc_common.create_cc_link_params(
            ctx = ctx,
            user_link_flags = user_link_flags,
            libraries_to_link = _to_depset(static_library),
        )
        no_static_no_shared = cc_common.create_cc_link_params(
            ctx = ctx,
            libraries_to_link = _to_depset(static_library),
        )

    return {"static_mode_params_for_dynamic_library": static_shared,
            "static_mode_params_for_executable": static_no_shared,
            "dynamic_mode_params_for_dynamic_library": no_static_shared,
            "dynamic_mode_params_for_executable": no_static_no_shared}

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
        files.shared_library,
        files.interface_library,
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
