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
    )
    return cc_external_rule_impl(ctx, attrs)

def _create_make_script(configureParameters):
    ctx = configureParameters.ctx
    attrs = configureParameters.attrs
    inputs = configureParameters.inputs

    root = detect_root(ctx.attr.lib_source)
    install_prefix = _get_install_prefix(ctx)

    tools = get_tools_info(ctx)
    flags = get_flags_info(ctx)

    data = ctx.attr.data or list()

    # Generate a list of arguments for make
    args = " ".join([
        ctx.expand_location(arg, data)
        for arg in ctx.attr.args
    ])

    make_commands = []

    if not ctx.attr.make_commands:
        for target in ctx.attr.targets:
            make_commands.append("{make} -C $$EXT_BUILD_ROOT$$/{root} {target} {args}".format(
                make = attrs.make_path,
                root = root,
                args = args,
                target = target,
            ))

    return create_make_script(
        workspace_name = ctx.workspace_name,
        tools = tools,
        flags = flags,
        root = root,
        user_vars = dict(ctx.attr.make_env_vars),
        deps = ctx.attr.deps,
        inputs = inputs,
        prefix = install_prefix,
        make_commands = make_commands,
    )

def _get_install_prefix(ctx):
    if ctx.attr.prefix:
        return ctx.attr.prefix
    return "$$INSTALLDIR$$"

def _attrs():
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
    attrs.update({
        "args": attr.string_list(
            doc = "A list of arguments to pass to the call to `make`",
        ),
        "keep_going": attr.bool(
            doc = (
                "__deprecated__: To maintain this behavior, pass `-k` to the `args` attribute " +
                "when not using the `make_commands` attribute."
            ),
            mandatory = False,
            default = True,
        ),
        "make_commands": attr.string_list(
            doc = (
                "__deprecated__: A list of hard coded bash commands for building source code. It's " +
                "recommended to leave this empty and use the `targets` + `args` attributes."
            ),
            mandatory = False,
            default = [],
        ),
        "make_env_vars": attr.string_dict(
            doc = "__deprecated__: Use the `env` attribute",
        ),
        "prefix": attr.string(
            doc = (
                "__deprecated__: To maintain this behavior, pass `PREFIX=<value>` to the `args` attribute"
            ),
            mandatory = False,
        ),
        "targets": attr.string_list(
            doc = (
                "A list of targets within the foreign build system to produce. An empty string (`\"\"`) will result in " +
                "a call to the underlying build system with no explicit target set"
            ),
            mandatory = False,
            default = ["", "install"],
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
