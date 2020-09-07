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
load("//tools/build_defs/native_tools:tool_access.bzl", "get_make_data")
load("@rules_foreign_cc//tools/build_defs:shell_script_helper.bzl", "os_name")

def _configure_make(ctx):
    make_data = get_make_data(ctx)

    tools_deps = ctx.attr.tools_deps + make_data.deps

    copy_results = "##copy_dir_contents_to_dir## $$BUILD_TMPDIR$$/$$INSTALL_PREFIX$$ $$INSTALLDIR$$\n"

    attrs = create_attrs(
        ctx.attr,
        configure_name = "Configure",
        create_configure_script = _create_configure_script,
        postfix_script = copy_results + "\n" + ctx.attr.postfix_script,
        tools_deps = tools_deps,
        make_path = make_data.path,
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
        deps = ctx.attr.deps,
        inputs = inputs,
        configure_in_place = ctx.attr.configure_in_place,
        autoreconf = ctx.attr.autoreconf,
        autoreconf_options = ctx.attr.autoreconf_options,
        autoreconf_env_vars = ctx.attr.autoreconf_env_vars,
        autogen = ctx.attr.autogen,
        autogen_command = ctx.attr.autogen_command,
        autogen_options = ctx.attr.autogen_options,
        autogen_env_vars = ctx.attr.autogen_env_vars,
    )
    return "\n".join([define_install_prefix, configure])

def _get_install_prefix(ctx):
    if ctx.attr.install_prefix:
        return ctx.attr.install_prefix
    if ctx.attr.lib_name:
        return ctx.attr.lib_name
    return ctx.attr.name

def _attrs():
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
    attrs.update({
        # The name of the configuration script file, default: configure.
        # The file must be in the root of the source directory.
        "configure_command": attr.string(default = "configure"),
        # Any options to be put on the 'configure' command line.
        "configure_options": attr.string_list(),
        # Environment variables to be set for the 'configure' invocation.
        "configure_env_vars": attr.string_dict(),
        # Install prefix, i.e. relative path to where to install the result of the build.
        # Passed to the 'configure' script with --prefix flag.
        "install_prefix": attr.string(mandatory = False),
        # Set to True if 'configure' should be invoked in place, i.e. from its enclosing
        # directory.
        "configure_in_place": attr.bool(mandatory = False, default = False),
        # Set to True if 'autoreconf' should be invoked before 'configure.',
        # currently requires 'configure_in_place' to be True.
        "autoreconf": attr.bool(mandatory = False, default = False),
        # Any options to be put in the 'autoreconf.sh' command line.
        "autoreconf_options": attr.string_list(),
        # Environment variables to be set for 'autoreconf' invocation.
        "autoreconf_env_vars": attr.string_dict(),
        # Set to True if 'autogen.sh' should be invoked before 'configure',
        # currently requires 'configure_in_place' to be True.
        "autogen": attr.bool(mandatory = False, default = False),
        # The name of the autogen script file, default: autogen.sh.
        # Many projects use autogen.sh however the Autotools FAQ recommends bootstrap
        # so we provide this option to support that.
        "autogen_command": attr.string(default = "autogen.sh"),
        # Any options to be put in the 'autogen.sh' command line.
        "autogen_options": attr.string_list(),
        # Environment variables to be set for 'autogen' invocation.
        "autogen_env_vars": attr.string_dict(),
    })
    return attrs

""" Rule for building external libraries with configure-make pattern.
 Some 'configure' script is invoked with --prefix=install (by default),
 and other parameters for compilation and linking, taken from Bazel C/C++
 toolchain and passed dependencies.
 After configuration, GNU Make is called.

 Attributes:
   See line comments in _attrs() method.
 Other attributes are documented in framework.bzl:CC_EXTERNAL_RULE_ATTRIBUTES
"""
configure_make = rule(
    attrs = _attrs(),
    fragments = ["cpp"],
    output_to_genfiles = True,
    implementation = _configure_make,
    toolchains = [
        "@rules_foreign_cc//tools/build_defs:make_toolchain",
        "@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:shell_commands",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)
