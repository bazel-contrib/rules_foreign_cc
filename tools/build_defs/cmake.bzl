""" Defines the rule for building external library with CMake
"""

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
load(":cmake_script.bzl", "create_cmake_script")

def _cmake_external(ctx):
    root = detect_root(ctx.attr.lib_source)
    install_prefix = _get_install_prefix(ctx)

    tools = get_tools_info(ctx)
    flags = get_flags_info(ctx)
    no_toolchain_file = ctx.attr.cache_entries.get("CMAKE_TOOLCHAIN_FILE") or not ctx.attr.generate_crosstool_file

    configure_script = create_cmake_script(ctx.workspace_name, tools, flags, install_prefix, root, no_toolchain_file, ctx.attr.cache_entries, ctx.attr.env_vars, ctx.attr.cmake_options)
    copy_results = "copy_dir_contents_to_dir $TMPDIR/{} $INSTALLDIR".format(install_prefix)

    tools_deps = ctx.attr.tools_deps + [ctx.attr._cmake_dep]
    attrs = create_attrs(
        ctx.attr,
        configure_name = "CMake",
        configure_script = configure_script,
        postfix_script = copy_results + "\n" + ctx.attr.postfix_script,
        tools_deps = tools_deps,
    )

    return cc_external_rule_impl(ctx, attrs)

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
        # Relative install prefix to be passed to CMake in -DCMAKE_INSTALL_PREFIX
        "install_prefix": attr.string(mandatory = False),
        # CMake cache entries to initialize (they will be passed with -Dkey=value)
        # Values, defined by the toolchain, will be joined with the values, passed here.
        # (Toolchain values come first)
        "cache_entries": attr.string_dict(mandatory = False, default = {}),
        # CMake environment variable values to join with toolchain-defined.
        # For example, additional CXXFLAGS.
        "env_vars": attr.string_dict(mandatory = False, default = {}),
        # Other CMake options
        "cmake_options": attr.string_list(mandatory = False, default = []),
        # When True, CMake crosstool file will be generated from the toolchain values,
        # provided cache-entries and env_vars (some values will still be passed as -Dkey=value
        # and environment variables).
        # If CMAKE_TOOLCHAIN_FILE cache entry is passed, specified crosstool file will be used
        # When using this option, it makes sense to specify CMAKE_SYSTEM_NAME in the
        # cache_entries - the rule makes only a poor guess about the target system,
        # it is better to specify it manually.
        "generate_crosstool_file": attr.bool(mandatory = False, default = False),
        "_cmake_dep": attr.label(
            default = "@foreign_cc_platform_utils//:cmake",
            cfg = "target",
            allow_files = True,
        ),
    })
    return attrs

""" Rule for building external library with CMake
 Attributes:
   cmake_options - (list of strings) options to be passed to the cmake call
 Other attributes are documented in framework.bzl:CC_EXTERNAL_RULE_ATTRIBUTES
"""
cmake_external = rule(
    attrs = _attrs(),
    fragments = ["cpp"],
    output_to_genfiles = True,
    implementation = _cmake_external,
)
