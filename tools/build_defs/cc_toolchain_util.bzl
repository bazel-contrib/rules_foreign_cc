""" Defines create_linking_info, which wraps passed libraries into CcLinkingInfo
 Due to the changes in Bazel Starlark API loads the correct version of implementation
 and re-exports them.
"""

load(
    "@foreign_cc_impl//:cc_toolchain_util.bzl",
    impl_CxxFlagsInfo = "CxxFlagsInfo",
    impl_CxxToolsInfo = "CxxToolsInfo",
    impl_LibrariesToLinkInfo = "LibrariesToLinkInfo",
    impl_absolutize_path_in_str = "absolutize_path_in_str",
    impl_create_linking_info = "create_linking_info",
    impl_get_env_vars = "get_env_vars",
    impl_get_flags_info = "get_flags_info",
    impl_get_tools_info = "get_tools_info",
    impl_is_debug_mode = "is_debug_mode",
    impl_targets_windows = "targets_windows",
)

CxxFlagsInfo = impl_CxxFlagsInfo
CxxToolsInfo = impl_CxxToolsInfo
LibrariesToLinkInfo = impl_LibrariesToLinkInfo
absolutize_path_in_str = impl_absolutize_path_in_str
create_linking_info = impl_create_linking_info
get_env_vars = impl_get_env_vars
get_flags_info = impl_get_flags_info
get_tools_info = impl_get_tools_info
is_debug_mode = impl_is_debug_mode
targets_windows = impl_targets_windows
