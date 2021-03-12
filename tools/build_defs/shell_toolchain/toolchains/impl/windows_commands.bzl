"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private/shell_toolchain/toolchains:impl/windows_commands.bzl",
    _assert_script_errors = "assert_script_errors",
    _cat = "cat",
    _children_to_path = "children_to_path",
    _cleanup_function = "cleanup_function",
    _copy_dir_contents_to_dir = "copy_dir_contents_to_dir",
    _define_absolute_paths = "define_absolute_paths",
    _define_function = "define_function",
    _echo = "echo",
    _env = "env",
    _export_var = "export_var",
    _if_else = "if_else",
    _increment_pkg_config_path = "increment_pkg_config_path",
    _local_var = "local_var",
    _mkdirs = "mkdirs",
    _os_name = "os_name",
    _path = "path",
    _pwd = "pwd",
    _redirect_out_err = "redirect_out_err",
    _replace_absolute_paths = "replace_absolute_paths",
    _replace_in_files = "replace_in_files",
    _script_prelude = "script_prelude",
    _symlink_contents_to_dir = "symlink_contents_to_dir",
    _symlink_to_dir = "symlink_to_dir",
    _touch = "touch",
    _use_var = "use_var",
)
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

assert_script_errors = _assert_script_errors
cat = _cat
children_to_path = _children_to_path
cleanup_function = _cleanup_function
copy_dir_contents_to_dir = _copy_dir_contents_to_dir
define_absolute_paths = _define_absolute_paths
define_function = _define_function
echo = _echo
env = _env
export_var = _export_var
if_else = _if_else
increment_pkg_config_path = _increment_pkg_config_path
local_var = _local_var
mkdirs = _mkdirs
os_name = _os_name
path = _path
pwd = _pwd
redirect_out_err = _redirect_out_err
replace_absolute_paths = _replace_absolute_paths
replace_in_files = _replace_in_files
script_prelude = _script_prelude
symlink_contents_to_dir = _symlink_contents_to_dir
symlink_to_dir = _symlink_to_dir
touch = _touch
use_var = _use_var
