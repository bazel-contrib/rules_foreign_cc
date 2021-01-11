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
load("//tools/build_defs/native_tools:tool_access.bzl", "get_waf_data")
load("@rules_foreign_cc//tools/build_defs:shell_script_helper.bzl", "os_name")

def _waf(ctx, **kwargs):
    waf_data = get_waf_data(ctx)

    tools_deps = ctx.attr.tools_deps + waf_data.deps

    copy_results = "##copy_dir_contents_to_dir## $$BUILD_TMPDIR$$/$$INSTALL_PREFIX$$ $$INSTALLDIR$$\n"

    attrs = create_attrs(
        ctx.attr,
        configure_name = "Configure",
        create_configure_script = _create_waf_configure_script,
        postfix_script = copy_results + "\n" + ctx.attr.postfix_script,
        tools_deps = tools_deps,
        make_path = waf_data.path,
        **kwargs
    )
    return cc_external_rule_impl(ctx, attrs)

def _create_waf_configure_script(configureParameters):
    attrs = configureParameters.attrs
    ctx = configureParameters.ctx
    inputs = configureParameters.inputs

    root = detect_root(ctx.attr.lib_source)

    tools = get_tools_info(ctx)
    flags = get_flags_info(ctx)

    return create_configure_script(
        workspace_name = ctx.workspace_name,
        # as default, pass execution OS as target OS
        target_os = os_name(ctx),
        tools = tools,
        flags = flags,
        root = root,
        user_options = ctx.attr.configure_options,
        user_vars = dict(ctx.attr.configure_env_vars),
        is_debug = is_debug_mode(ctx),
        configure_command = ctx.attr.configure_command,
        configure_script = "",
        deps = ctx.attr.deps,
        inputs = inputs,
        configure_in_place = True,
    )

def _attrs():
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
    attrs.update({
        "configure_command": attr.string(default = "waf configure"),
        "configure_options": attr.string_list(),
        "configure_env_vars": attr.string_dict(),
        "make_commands": attr.string_list(mandatory = False, default = ["waf -j`nproc`", "waf install"]),
    })
    return attrs

waf = rule(
    attrs = _attrs(),
    fragments = ["cpp"],
    output_to_genfiles = True,
    implementation = _waf,
    toolchains = [
        "@rules_foreign_cc//tools/build_defs:waf_toolchain",
        "@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:shell_commands",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)
