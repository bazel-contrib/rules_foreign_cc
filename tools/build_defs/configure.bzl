load(
    "//tools/build_defs:framework.bzl",
    "CC_EXTERNAL_RULE_ATTRIBUTES",
    "cc_external_rule_impl",
    "create_attrs",
)
load(
    "//tools/build_defs:detect_root.bzl",
    "detect_root",
)
load(
    "//tools/build_defs:cc_toolchain_util.bzl",
    "get_flags_info",
    "get_tools_info",
    "is_debug_mode",
)
load(":configure_script.bzl", "create_configure_script")
load("@rules_foreign_cc//tools/build_defs:shell_script_helper.bzl", "os_name")

def _configure_make(ctx):
    copy_results = "copy_dir_contents_to_dir $$BUILD_TMPDIR$$/$$INSTALL_PREFIX$$ $$INSTALLDIR$$\n"

    attrs = create_attrs(
        ctx.attr,
        configure_name = "Configure",
        create_configure_script = _create_configure_script,
        postfix_script = copy_results + "\n" + ctx.attr.postfix_script,
    )
    return cc_external_rule_impl(ctx, attrs)

def _create_configure_script(configureParameters):
    ctx = configureParameters.ctx
    inputs = configureParameters.inputs

    root = detect_root(ctx.attr.lib_source)
    install_prefix = _get_install_prefix(ctx)

    tools = get_tools_info(ctx)
    flags = get_flags_info(ctx)

    define_install_prefix = "export INSTALL_PREFIX=\"" + _get_install_prefix(ctx) + "\"\n"

    configure = create_configure_script(
        ctx.workspace_name,
        # as default, pass execution OS as target OS
        os_name(ctx),
        tools,
        flags,
        root,
        ctx.attr.configure_options,
        dict(ctx.attr.configure_env_vars),
        is_debug_mode(ctx),
        ctx.attr.configure_command,
        ctx.attr.deps,
        inputs,
    )
    return "\n".join([define_install_prefix, configure])

def _get_install_prefix(ctx):
    if ctx.attr.install_prefix:
        prefix = ctx.attr.install_prefix

        # If not in sandbox, or after the build, the value can be absolute.
        # So if the user passed the absolute value, do not touch it.
        if (prefix.startswith("/")):
            return prefix
        return prefix if prefix.startswith("./") else "./" + prefix
    if ctx.attr.lib_name:
        return "./" + ctx.attr.lib_name
    return "./" + ctx.attr.name

def _attrs():
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
    attrs.update({
        # default: configure
        "configure_command": attr.string(default = "configure"),
        "configure_options": attr.string_list(),
        "configure_env_vars": attr.string_dict(),
        "install_prefix": attr.string(mandatory = False),
    })
    return attrs

configure_make = rule(
    attrs = _attrs(),
    fragments = ["cpp"],
    output_to_genfiles = True,
    implementation = _configure_make,
    toolchains = ["@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:shell_commands"],
)
