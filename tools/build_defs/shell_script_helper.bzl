"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private:shell_script_helper.bzl",
    _convert_shell_script = "convert_shell_script",
    _convert_shell_script_by_context = "convert_shell_script_by_context",
    _create_function = "create_function",
    _do_function_call = "do_function_call",
    _extract_wrapped = "extract_wrapped",
    _get_function_name = "get_function_name",
    _os_name = "os_name",
    _replace_exports = "replace_exports",
    _replace_var_ref = "replace_var_ref",
    _split_arguments = "split_arguments",
)
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

os_name = _os_name
create_function = _create_function
convert_shell_script = _convert_shell_script
convert_shell_script_by_context = _convert_shell_script_by_context
replace_var_ref = _replace_var_ref
replace_exports = _replace_exports
get_function_name = _get_function_name
extract_wrapped = _extract_wrapped
do_function_call = _do_function_call
split_arguments = _split_arguments
