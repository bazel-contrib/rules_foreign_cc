"""Policy facade for runtime library search path derivation."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(":runtime_search_paths.bzl", "derive_runtime_library_search_directories")

RUNTIME_LIBRARY_SEARCH_DIRECTORY_ATTRIBUTES = {
    "additional_dynamic_runtime_library_search_origins": attr.string_list(
        doc = (
            "Additional install-tree-relative origins for shared-library " +
            "link actions. Values are relative to this rule's install " +
            "directory and should not include lib_name or the rule name. " +
            "For each origin, runtime library search directories are derived " +
            "so shared libraries loaded from that origin can find shared " +
            "libraries from deps, dynamic_deps, and this rule's own declared " +
            "shared-library outputs."
        ),
        mandatory = False,
        default = [],
    ),
    "additional_executable_runtime_library_search_origins": attr.string_list(
        doc = (
            "Additional install-tree-relative origins for executable link " +
            "actions. Values are relative to this rule's install directory " +
            "and should not include lib_name or the rule name. For each " +
            "origin, runtime library search directories are derived so " +
            "executables loaded from that origin can find shared libraries " +
            "from deps, dynamic_deps, and this rule's own declared " +
            "shared-library outputs."
        ),
        mandatory = False,
        default = [],
    ),
    "runtime_library_search_directories": attr.string(
        doc = (
            "Controls whether this target derives runtime library search " +
            "directories. Use 'auto' to follow the global " +
            "@rules_foreign_cc//foreign_cc/settings:runtime_library_search_directories " +
            "build setting, 'enabled' to force it on for this target, or " +
            "'disabled' to force it off. Global enablement is a strict Unix " +
            "conformance switch: Unix targets that declare shared-library " +
            "outputs must support the rule-specific shared-link flag hook or " +
            "set runtime_library_search_directories = 'disabled'. This is " +
            "not supported for Windows C++ toolchains; explicit per-target " +
            "'enabled' fails on Windows, while 'auto' with global enablement " +
            "is ignored on Windows. On macOS, derived runtime search paths also " +
            "require compatible Mach-O @rpath install names and load " +
            "commands. This feature passes runtime search directories to " +
            "link actions, but does not rewrite installed dylib " +
            "IDs or load commands after the upstream install step. Upstream " +
            "builds may need to emit or preserve @rpath/... install names."
        ),
        mandatory = False,
        values = ["auto", "enabled", "disabled"],
        default = "auto",
    ),
    "_runtime_library_search_directories": attr.label(
        default = Label("//foreign_cc/settings:runtime_library_search_directories"),
        providers = [BuildSettingInfo],
    ),
}

# Policy helpers.

# Returns true when the target explicitly forces runtime search on.
def _runtime_library_search_directories_explicitly_enabled(ctx):
    return getattr(ctx.attr, "runtime_library_search_directories", "disabled") == "enabled"

def _runtime_library_search_directories_requested(ctx):
    value = getattr(ctx.attr, "runtime_library_search_directories", "disabled")
    if value == "enabled":
        return True
    if value == "disabled":
        return False

    setting = getattr(ctx.attr, "_runtime_library_search_directories", None)
    return setting[BuildSettingInfo].value == "enabled"

def runtime_library_search_directories_enabled(ctx, is_windows):
    """Returns true when runtime search is effectively enabled.

    Runtime search can be requested explicitly by the target or inherited from
    the global build setting. On Windows, explicit target opt-in fails because
    runtime search is unsupported, while inherited global enablement through
    `auto` is treated as a no-op.

    Args:
      ctx: Rule context.
      is_windows: Whether the target C++ toolchain is for Windows.

    Returns:
      True when runtime search should be derived and passed to link variables.
    """

    if is_windows:
        if _runtime_library_search_directories_explicitly_enabled(ctx):
            fail((
                "ERROR: {} sets runtime_library_search_directories = " +
                "\"enabled\", but runtime library search directories are not " +
                "supported on Windows. Set runtime_library_search_directories " +
                "= \"disabled\" for this target, or leave it as \"auto\" so " +
                "global Unix conformance enablement is ignored on Windows."
            ).format(ctx.label))
        return False

    return _runtime_library_search_directories_requested(ctx)

def enforce_runtime_search_shared_ldflags_attr(
        ctx,
        runtime_search_enabled,
        cxx_linker_shared,
        hook_attr_name):
    """Fails if runtime enabled targets cannot receive shared linker flags.

    Rules that declare `out_shared_libs` need a rule-specific hook for
    shared-library linker flags whenever runtime search is enabled. Without that
    hook, the derived rpaths for the produced shared libraries cannot be passed
    to the upstream build system's shared-library link actions.

    Args:
      ctx: Rule context.
      runtime_search_enabled: Whether runtime search is effectively enabled for
        this target platform.
      cxx_linker_shared: Shared-library linker flags derived from the target C++
        toolchain.
      hook_attr_name: Name of the rule attr that forwards shared-library linker
        flags to the upstream build system, such as `shared_ldflags_vars` or
        `shared_ldflags_option`.
    """

    if (
        runtime_search_enabled and
        ctx.attr.out_shared_libs and
        cxx_linker_shared and
        not getattr(ctx.attr, hook_attr_name)
    ):
        fail((
            "ERROR: {} enables runtime_library_search_directories and " +
            "declares shared-library outputs via out_shared_libs = {}, but " +
            "{} is not set. The shared-library runtime search linker flags " +
            "cannot be propagated to upstream shared-library link actions. " +
            "Set {} to the upstream shared-link flag hook, or opt out with " +
            "runtime_library_search_directories = \"disabled\"."
        ).format(
            ctx.label,
            ctx.attr.out_shared_libs,
            hook_attr_name,
            hook_attr_name,
        ))

def _declared_runtime_attrs(ctx):
    runtime_attrs = []
    for attr_name in [
        "additional_dynamic_runtime_library_search_origins",
        "additional_executable_runtime_library_search_origins",
    ]:
        if getattr(ctx.attr, attr_name, []):
            runtime_attrs.append(attr_name)
    return runtime_attrs

def _has_outputs_for_runtime_path(outputs):
    return bool(
        outputs.libraries.shared_libraries or
        outputs.out_binary_files or
        outputs.data_dirs or
        outputs.data_files,
    )

def runtime_library_search_directories(ctx, outputs):
    """Returns runtime library search directories for link actions.

    Args:
      ctx: Rule context.
      outputs: Framework-declared outputs. Shared libraries and binaries provide
        the default runtime origins; one of them is also used to recover
        INSTALLDIR in `File.short_path` space.

    Returns:
      A struct with `shared_dirs` and `executable_dirs` depset fields. Each field
      contains runtime library search directories for that link action kind, or
      None when runtime library search directory derivation is disabled.
    """
    d_attrs = _declared_runtime_attrs(ctx)

    d_attrs = _declared_runtime_attrs(ctx)
    if not _runtime_library_search_directories_requested(ctx):
        if d_attrs:
            fail((
                "FAIL: {} sets runtime_library_search attrs ({}) but " +
                "runtime_library_search_directories is disabled."
            ).format(ctx.label, ", ".join(d_attrs)))
        return struct(shared_dirs = None, executable_dirs = None)

    # If no outputs are expected, we don't need to worry about
    # runtime library search directories.
    if outputs == None:
        return struct(shared_dirs = None, executable_dirs = None)

    if d_attrs and not _has_outputs_for_runtime_path(outputs):
        fail((
            "{} sets runtime_library_search attrs ({}) but none of the outputs " +
            "(out_shared_libs, out_binaries, out_data_dirs, or out_data_files) " +
            "needing runtime path is declared."
        ).format(ctx.label, ", ".join(d_attrs)))

    return derive_runtime_library_search_directories(ctx, outputs)

export_for_test = struct(
    runtime_library_search_directories_requested = _runtime_library_search_directories_requested,
)
