"""A module defining default toolchain info for the foreign_cc framework"""

def _toolchain_mapping(file, exec_compatible_with = [], target_compatible_with = []):
    """Mapping of toolchain definition files to platform constraints

    Args:
        file (Label): Toolchain definition file
        exec_compatible_with (list): A list of compatible execution platform constraints.
        target_compatible_with (list): Compatible target platform constraints

    Returns:
        struct: A collection of toolchain data
    """
    return struct(
        file = file,
        exec_compatible_with = exec_compatible_with,
        target_compatible_with = target_compatible_with,
    )

# This list is the single entrypoint for all foreing_cc framework toolchains.
TOOLCHAIN_MAPPINGS = [
    _toolchain_mapping(
        exec_compatible_with = [
            "@platforms//os:linux",
        ],
        file = Label("@rules_foreign_cc//foreign_cc/private/framework/toolchains:linux_commands.bzl"),
    ),
    _toolchain_mapping(
        exec_compatible_with = [
            "@platforms//os:windows",
        ],
        file = Label("@rules_foreign_cc//foreign_cc/private/framework/toolchains:windows_commands.bzl"),
    ),
    _toolchain_mapping(
        exec_compatible_with = [
            "@platforms//os:macos",
        ],
        file = Label("@rules_foreign_cc//foreign_cc/private/framework/toolchains:macos_commands.bzl"),
    ),
]
