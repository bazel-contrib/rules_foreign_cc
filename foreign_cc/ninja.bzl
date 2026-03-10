"""A rule for building projects using the [Ninja](https://ninja-build.org/) build tool"""

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load("@rules_cc//cc:defs.bzl", "CcInfo")
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
    "expand_locations_and_make_variables",
)
load("//foreign_cc/private:ninja_script.bzl", "create_ninja_script")
load("//toolchains/native_tools:tool_access.bzl", "get_ninja_data")

def _ninja_impl(ctx):
    """The implementation of the `ninja` rule

    Args:
        ctx (ctx): The rule's context object

    Returns:
        list: A list of providers. See `cc_external_rule_impl`
    """
    ninja_data = get_ninja_data(ctx)

    tools_data = [ninja_data]

    attrs = create_attrs(
        ctx.attr,
        configure_name = "Ninja",
        create_configure_script = _create_ninja_script,
        tools_data = tools_data,
        ninja_path = ninja_data.path,
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
    attrs = configureParameters.attrs
    inputs = configureParameters.inputs

    root = detect_root(ctx.attr.lib_source)

    tools = get_tools_info(ctx)
    flags = get_flags_info(ctx)

    data = ctx.attr.data + ctx.attr.build_data

    # Generate a list of arguments for ninja
    args = " ".join([
        ctx.expand_location(arg, data)
        for arg in ctx.attr.args
    ])

    # Set the directory location for the build commands
    directory = "$$EXT_BUILD_ROOT$$/{}".format(root)
    if ctx.attr.directory:
        directory = ctx.expand_location(ctx.attr.directory, data)

    user_env = expand_locations_and_make_variables(ctx, ctx.attr.env, "env", data)

    prefix = "{} ".format(expand_locations_and_make_variables(ctx, attrs.tool_prefix, "tool_prefix", data)) if attrs.tool_prefix else ""

    cc_toolchain = find_cpp_toolchain(ctx)
    is_msvc = cc_toolchain.compiler == "msvc-cl"

    return create_ninja_script(
        workspace_name = ctx.workspace_name,
        tools = tools,
        flags = flags,
        root = root,
        deps = ctx.attr.deps,
        inputs = inputs,
        env_vars = user_env,
        ninja_prefix = prefix,
        ninja_path = attrs.ninja_path,
        ninja_targets = ctx.attr.targets or [""],
        ninja_args = args,
        ninja_directory = directory,
        is_msvc = is_msvc,
    )

def _attrs():
    """Modifies the common set of attributes used by rules_foreign_cc and sets Ninja specific attrs

    Returns:
        dict: Attributes of the `ninja` rule
    """
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)

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
    })
    return attrs

ninja = rule(
    doc = (
        "Rule for building external libraries with [Ninja](https://ninja-build.org/)."
    ),
    attrs = _attrs(),
    fragments = CC_EXTERNAL_RULE_FRAGMENTS,
    output_to_genfiles = True,
    provides = [CcInfo],
    implementation = _ninja_impl,
    toolchains = [
        "@rules_foreign_cc//toolchains:ninja_toolchain",
        "@rules_foreign_cc//foreign_cc/private/framework:shell_toolchain",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)
