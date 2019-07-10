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
)
load(":configure_script.bzl", "create_make_script")

def _make(ctx):
    attrs = create_attrs(
        ctx.attr,
        configure_name = "GNUMake",
        create_configure_script = _create_make_script,
        make_commands = [],
    )
    return cc_external_rule_impl(ctx, attrs)

def _create_make_script(configureParameters):
    ctx = configureParameters.ctx
    inputs = configureParameters.inputs

    root = detect_root(ctx.attr.lib_source)
    install_prefix = _get_install_prefix(ctx)

    tools = get_tools_info(ctx)
    flags = get_flags_info(ctx)

    make_commands = ctx.attr.make_commands or [
        "make %s -C $$EXT_BUILD_ROOT$$/%s" % ("-k" if ctx.attr.keep_going else "", root),
        "make -C $$EXT_BUILD_ROOT$$/%s install PREFIX=%s" % (root, install_prefix),
    ]

    return create_make_script(
        workspace_name = ctx.workspace_name,
        tools = tools,
        flags = flags,
        root = root,
        user_vars = dict(ctx.attr.make_env_vars),
        deps = ctx.attr.deps,
        inputs = inputs,
        make_commands = make_commands,
        prefix = install_prefix,
    )

def _get_install_prefix(ctx):
    if ctx.attr.prefix:
        return ctx.attr.prefix
    return "$$INSTALLDIR$$"

def _attrs():
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
    attrs.update({
        # Environment variables to be set for the 'configure' invocation.
        "make_env_vars": attr.string_dict(),
        # Install prefix, an absolute path.
        # Passed to the GNU make via "make install PREFIX=<value>".
        # By default, the install directory created under sandboxed execution root is used.
        # Build results are copied to the Bazel's output directory, so the prefix is only important
        # if it is recorded into any text files by Makefile script.
        # In that case, it is important to note that rules_foreign_cc is overriding the paths under
        # execution root with "BAZEL_GEN_ROOT" value.
        "prefix": attr.string(mandatory = False),
        # Overriding make_commands default value to be empty,
        # then we can provide better default value programmatically
        "make_commands": attr.string_list(mandatory = False, default = []),
        # Keep going when some targets can not be made, -k flag is passed to make
        # (applies only if make_commands attribute is not set).
        # Please have a look at _create_make_script for default make_commands.
        "keep_going": attr.bool(mandatory = False, default = True),
    })
    return attrs

"""Rule for building external libraries with GNU Make.
 GNU Make commands (make and make install by default) are invoked with prefix="install"
 (by default), and other environment variables for compilation and linking, taken from Bazel C/C++
 toolchain and passed dependencies.

 Attributes:
   See line comments in _attrs() method.
 Other attributes are documented in framework.bzl:CC_EXTERNAL_RULE_ATTRIBUTES
"""
make = rule(
    attrs = _attrs(),
    fragments = ["cpp"],
    output_to_genfiles = True,
    implementation = _make,
    toolchains = [
        "@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:shell_commands",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)
