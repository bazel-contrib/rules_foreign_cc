"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private:configure_script.bzl",
    _create_configure_script = "create_configure_script",
    _create_make_script = "create_make_script",
    _get_env_vars = "get_env_vars",
)
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

create_configure_script = _create_configure_script
create_make_script = _create_make_script
get_env_vars = _get_env_vars
