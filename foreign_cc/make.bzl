# buildifier: disable=module-docstring
load(
    "//foreign_cc/private:cc_toolchain_util.bzl",
    "get_flags_info",
    "get_tools_info",
)
load(
    "//foreign_cc/private:detect_root.bzl",
    "detect_root",
)
load(
    "//foreign_cc/private:framework.bzl",
    "CC_EXTERNAL_RULE_ATTRIBUTES",
    "CC_EXTERNAL_RULE_FRAGMENTS",
    "cc_external_rule_impl",
    "create_attrs",
)
load("//foreign_cc/private:make_script.bzl", "create_make_script")
load("//toolchains/native_tools:tool_access.bzl", "get_make_data")

def _make(ctx):
    make_data = get_make_data(ctx)

    tools_deps = ctx.attr.tools_deps + make_data.deps

    attrs = create_attrs(
        ctx.attr,
        configure_name = "GNUMake",
        create_configure_script = _create_make_script,
        tools_deps = tools_deps,
        make_path = make_data.path,
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
        "{make} {keep_going} -C $$EXT_BUILD_ROOT$$/{root}".format(
            make = configureParameters.attrs.make_path,
            keep_going = "-k" if ctx.attr.keep_going else "",
            root = root,
        ),
        "{make} -C $$EXT_BUILD_ROOT$$/{root} install PREFIX={prefix}".format(
            make = configureParameters.attrs.make_path,
            root = root,
            prefix = install_prefix,
        ),
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
        "keep_going": attr.bool(
            doc = (
                "Keep going when some targets can not be made, -k flag is passed to make " +
                "(applies only if make_commands attribute is not set). " +
                "Please have a look at _create_make_script for default make_commands."
            ),
            mandatory = False,
            default = True,
        ),
        "make_commands": attr.string_list(
            doc = (
                "Overriding make_commands default value to be empty, " +
                "then we can provide better default value programmatically "
            ),
            mandatory = False,
            default = [],
        ),
        "make_env_vars": attr.string_dict(
            doc = "Environment variables to be set for the 'configure' invocation.",
        ),
        "prefix": attr.string(
            doc = (
                "Install prefix, an absolute path. " +
                "Passed to the GNU make via \"make install PREFIX=<value>\". " +
                "By default, the install directory created under sandboxed execution root is used. " +
                "Build results are copied to the Bazel's output directory, so the prefix is only important " +
                "if it is recorded into any text files by Makefile script. " +
                "In that case, it is important to note that rules_foreign_cc is overriding the paths under " +
                "execution root with \"BAZEL_GEN_ROOT\" value."
            ),
            mandatory = False,
        ),
    })
    return attrs

make = rule(
    doc = (
        "Rule for building external libraries with GNU Make. " +
        "GNU Make commands (make and make install by default) are invoked with prefix=\"install\" " +
        "(by default), and other environment variables for compilation and linking, taken from Bazel C/C++ " +
        "toolchain and passed dependencies."
    ),
    attrs = _attrs(),
    fragments = CC_EXTERNAL_RULE_FRAGMENTS,
    output_to_genfiles = True,
    implementation = _make,
    toolchains = [
        "@rules_foreign_cc//toolchains:make_toolchain",
        "@rules_foreign_cc//foreign_cc/private/shell_toolchain/toolchains:shell_commands",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)
