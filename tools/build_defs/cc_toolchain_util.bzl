"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private:cc_toolchain_util.bzl",
    _CxxFlagsInfo = "CxxFlagsInfo",
    _CxxToolsInfo = "CxxToolsInfo",
    _LibrariesToLinkInfo = "LibrariesToLinkInfo",
    _absolutize_path_in_str = "absolutize_path_in_str",
    _create_linking_info = "create_linking_info",
    _get_env_vars = "get_env_vars",
    _get_flags_info = "get_flags_info",
    _get_tools_info = "get_tools_info",
    _is_debug_mode = "is_debug_mode",
    _targets_windows = "targets_windows",
)
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

CxxFlagsInfo = _CxxFlagsInfo
CxxToolsInfo = _CxxToolsInfo
LibrariesToLinkInfo = _LibrariesToLinkInfo
absolutize_path_in_str = _absolutize_path_in_str
create_linking_info = _create_linking_info
get_env_vars = _get_env_vars
get_flags_info = _get_flags_info
get_tools_info = _get_tools_info
is_debug_mode = _is_debug_mode
targets_windows = _targets_windows
