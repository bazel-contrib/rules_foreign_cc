""" Defines the rule for building external library with CMake
"""

load(
    "//foreign_cc/private:cc_toolchain_util.bzl",
    "get_flags_info",
    "get_tools_info",
    "is_debug_mode",
)
load("//foreign_cc/private:cmake_script.bzl", "create_cmake_script")
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
load(
    "//toolchains/native_tools:tool_access.bzl",
    "get_cmake_data",
    "get_make_data",
    "get_ninja_data",
)

def _cmake_impl(ctx):
    cmake_data = get_cmake_data(ctx)
    make_data = get_make_data(ctx)

    tools_deps = ctx.attr.tools_deps + cmake_data.deps + make_data.deps

    ninja_data = get_ninja_data(ctx)
    make_commands = ctx.attr.make_commands
    if _uses_ninja(ctx.attr.make_commands):
        tools_deps += ninja_data.deps
        make_commands = [command.replace("ninja", ninja_data.path) for command in make_commands]

    attrs = create_attrs(
        ctx.attr,
        configure_name = "CMake",
        create_configure_script = _create_configure_script,
        postfix_script = "##copy_dir_contents_to_dir## $$BUILD_TMPDIR$$/$$INSTALL_PREFIX$$ $$INSTALLDIR$$\n" + ctx.attr.postfix_script,
        tools_deps = tools_deps,
        cmake_path = cmake_data.path,
        ninja_path = ninja_data.path,
        make_path = make_data.path,
        make_commands = make_commands,
    )

    return cc_external_rule_impl(ctx, attrs)

def _uses_ninja(make_commands):
    for command in make_commands:
        (before, separator, after) = command.partition(" ")
        if before == "ninja":
            return True
    return False

def _create_configure_script(configureParameters):
    ctx = configureParameters.ctx
    inputs = configureParameters.inputs

    root = detect_root(ctx.attr.lib_source)
    if len(ctx.attr.working_directory) > 0:
        root = root + "/" + ctx.attr.working_directory

    tools = get_tools_info(ctx)

    # CMake will replace <TARGET> with the actual output file
    flags = get_flags_info(ctx, "<TARGET>")
    no_toolchain_file = ctx.attr.cache_entries.get("CMAKE_TOOLCHAIN_FILE") or not ctx.attr.generate_crosstool_file

    define_install_prefix = "export INSTALL_PREFIX=\"" + _get_install_prefix(ctx) + "\""
    configure_script = create_cmake_script(
        ctx,
        workspace_name = ctx.workspace_name,
        cmake_path = configureParameters.attrs.cmake_path,
        tools = tools,
        flags = flags,
        install_prefix = "$$INSTALL_PREFIX$$",
        root = root,
        no_toolchain_file = no_toolchain_file,
        user_cache = dict(ctx.attr.cache_entries),
        user_env = dict(ctx.attr.env_vars),
        options = ctx.attr.cmake_options,
        include_dirs = inputs.include_dirs,
        is_debug_mode = is_debug_mode(ctx),
    )
    return struct(
        commands = [define_install_prefix] + configure_script.commands,
        files = configure_script.files
    )

def _get_install_prefix(ctx):
    if ctx.attr.install_prefix:
        return ctx.attr.install_prefix
    if ctx.attr.lib_name:
        return ctx.attr.lib_name
    return ctx.attr.name

def _attrs():
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
    attrs.update({
        "cache_entries": attr.string_dict(
            doc = (
                "CMake cache entries to initialize (they will be passed with -Dkey=value) " +
                "Values, defined by the toolchain, will be joined with the values, passed here. " +
                "(Toolchain values come first)"
            ),
            mandatory = False,
            default = {},
        ),
        "cmake_options": attr.string_list(
            doc = "Other CMake options",
            mandatory = False,
            default = [],
        ),
        "env_vars": attr.string_dict(
            doc = (
                "CMake environment variable values to join with toolchain-defined. " +
                "For example, additional CXXFLAGS."
            ),
            mandatory = False,
            default = {},
        ),
        "generate_crosstool_file": attr.bool(
            doc = (
                "When True, CMake crosstool file will be generated from the toolchain values, " +
                "provided cache-entries and env_vars (some values will still be passed as -Dkey=value " +
                "and environment variables). " +
                "If CMAKE_TOOLCHAIN_FILE cache entry is passed, specified crosstool file will be used " +
                "When using this option to cross-compile, it is required to specify CMAKE_SYSTEM_NAME in the " +
                "cache_entries"
            ),
            mandatory = False,
            default = True,
        ),
        "install_prefix": attr.string(
            doc = "Relative install prefix to be passed to CMake in -DCMAKE_INSTALL_PREFIX",
            mandatory = False,
        ),
        "working_directory": attr.string(
            doc = (
                "Working directory, with the main CMakeLists.txt " +
                "(otherwise, the top directory of the lib_source label files is used.)"
            ),
            mandatory = False,
            default = "",
        ),
    })
    return attrs

cmake = rule(
    doc = "Rule for building external library with CMake.",
    attrs = _attrs(),
    fragments = CC_EXTERNAL_RULE_FRAGMENTS,
    output_to_genfiles = True,
    implementation = _cmake_impl,
    toolchains = [
        "@rules_foreign_cc//toolchains:cmake_toolchain",
        "@rules_foreign_cc//toolchains:ninja_toolchain",
        "@rules_foreign_cc//toolchains:make_toolchain",
        "@rules_foreign_cc//foreign_cc/private/shell_toolchain/toolchains:shell_commands",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)
