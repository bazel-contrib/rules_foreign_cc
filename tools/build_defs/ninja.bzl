"""A module defining the `ninja` rule. A rule for building projects using the Ninja build tool"""

load(
    "//tools/build_defs:detect_root.bzl",
    "detect_root",
)
load(
    "//tools/build_defs:framework.bzl",
    "CC_EXTERNAL_RULE_ATTRIBUTES",
    "cc_external_rule_impl",
    "create_attrs",
)
load("//tools/build_defs/native_tools:tool_access.bzl", "get_ninja_data")

def _ninja_impl(ctx):
    """The implementation of the `ninja` rule

    Args:
        ctx (ctx): The rule's context object

    Returns:
        list: A list of providers. See `cc_external_rule_impl`
    """
    ninja_data = get_ninja_data(ctx)

    tools_deps = ctx.attr.tools_deps + ninja_data.deps

    attrs = create_attrs(
        ctx.attr,
        configure_name = "Ninja",
        create_configure_script = _create_ninja_script,
        tools_deps = tools_deps,
        ninja_path = ninja_data.path,
        make_commands = [],
    )
    return cc_external_rule_impl(ctx, attrs)

def _create_ninja_script(configureParameters):
    """Creates the bash commands for invoking commands to build ninja projects

    Args:
        configureParameters (struct): See `ConfigureParameters`

    Returns:
        str: A string representing a section of a bash script
    """
    ctx = configureParameters.ctx

    script = []

    root = detect_root(ctx.attr.lib_source)
    script.append("##symlink_contents_to_dir## $$EXT_BUILD_ROOT$$/{} $$BUILD_TMPDIR$$".format(root))

    data = ctx.attr.data or list()

    # Generate a list of arguments for ninja
    args = " ".join([
        ctx.expand_location(arg, data)
        for arg in ctx.attr.args
    ])

    # Set the directory location for the build commands
    directory = "$$EXT_BUILD_ROOT$$/{}".format(root)
    if ctx.attr.directory:
        directory = ctx.expand_location(ctx.attr.directory, data)

    # Generate commands for all the targets, ensuring there's
    # always at least 1 call to the default target.
    for target in ctx.attr.targets or [""]:
        # Note that even though directory is always passed, the
        # following arguments can take precedence.
        script.append("{ninja} -C {dir} {args} {target}".format(
            ninja = configureParameters.attrs.ninja_path,
            dir = directory,
            args = args,
            target = target,
        ))

    return "\n".join(script)

def _attrs():
    """Modifies the common set of attributes used by rules_foreign_cc and sets Ninja specific attrs

    Returns:
        dict: Attributes of the `ninja` rule
    """
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)

    # Drop old vars
    attrs.pop("make_commands")

    attrs.update({
        "args": attr.string_list(
            doc = "A list of arguments to pass to the call to `ninja`",
        ),
        "directory": attr.string(
            doc = (
                "A directory to pass as the `-C` argument. The rule will always use the root " +
                "directory of the `lib_sources` attribute if this attribute is not set"
            ),
        ),
        "targets": attr.string_list(
            doc = (
                "A list of ninja targets to build. To call the default target, simply pass `\"\"` as " +
                "one of the items to this attribute."
            ),
        ),
    })
    return attrs

ninja = rule(
    doc = (
        "Rule for building external libraries with [Ninja](https://ninja-build.org/)."
    ),
    attrs = _attrs(),
    fragments = ["cpp"],
    output_to_genfiles = True,
    implementation = _ninja_impl,
    toolchains = [
        "@rules_foreign_cc//tools/build_defs:ninja_toolchain",
        "@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:shell_commands",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)
