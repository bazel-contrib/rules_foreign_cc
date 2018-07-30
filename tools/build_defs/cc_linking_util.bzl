""" Defines create_linking_info, which wraps passed libraries into CcLinkingInfo
"""

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

LibrariesToLinkInfo = provider(
    doc = "Libraries to be wrapped into CcLinkingInfo",
    fields = dict(
     static_libraries = "Static library files, optional",
     shared_libraries = "Dynamic library files, optional",
     interface_libraries = "Interface library files, optional",
))

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
    if system_provided and shared_library_artifacts != None:
        fail("'shared_library' shouldn't be specified when 'system_provided' is true")

    # If a shared library won't be provided by system during runtime and we are linking the shared
    # library through interface library, the shared library must be specified.
    if (not system_provided and shared_library_artifacts == None and
        interface_library_artifacts != None):
        fail("'shared_library' should be specified when 'system_provided' is false")

    if targets_windows and shared_library_artifacts != None:
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

# we could possibly take a decision about linking interface/shared library beased on each library name
# (usefull for the case when multiple output targets are provided)
def _build_libraries_to_link_and_runtime_artifact(ctx, files, cc_toolchain, targets_windows):
    static_libraries = [_build_static_library_to_link(ctx, lib) for lib in (files.static_libraries or [])]

    shared_libraries = []
    runtime_artifacts = []
    if files.shared_libraries != None:
      for lib in files.shared_libraries:
        shared_library += _build_shared_library_to_link(ctx, lib, cc_toolchain, targets_windows)
        runtime_artifact += shared_library.artifact()

    interface_libraries = []
    if files.interface_libraries != None:
      for lib in files.interface_libraries:
        interface_libraries += _build_interface_library_to_link(ctx, lib, cc_toolchain, targets_windows)

    dynamic_libraries_for_linking = None
    if len(interface_libraries) > 0:
        dynamic_libraries_for_linking = interface_libraries
    else:
        dynamic_libraries_for_linking = shared_libraries

    return {"static_libraries": static_libraries,
            "dynamic_libraries": dynamic_libraries_for_linking,
            "runtime_artifacts": runtime_artifacts}

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
