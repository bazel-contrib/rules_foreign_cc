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
load("//toolchains/native_tools:tool_access.bzl", "get_cmake_data", "get_ninja_data")

def _cmake_impl(ctx):
    cmake_data = get_cmake_data(ctx)
    ninja_path = None

    tools_deps = ctx.attr.tools_deps + cmake_data.deps

    # For generators using ninja, make sure it's available
    for option in ctx.attr.cmake_options:
        if "ninja" in option.lower():
            ninja_data = get_ninja_data(ctx)
            ninja_path = ninja_data.path
            tools_deps.extend(ninja_data.deps)
            break

    attrs = create_attrs(
        ctx.attr,
        configure_name = "CMake",
        create_configure_script = _create_configure_script,
        postfix_script = "##copy_dir_contents_to_dir## $$BUILD_TMPDIR$$/$$INSTALL_PREFIX$$ $$INSTALLDIR$$\n" + ctx.attr.postfix_script,
        tools_deps = tools_deps,
        cmake_path = cmake_data.path,
        ninja_path = ninja_path,
    )

    return cc_external_rule_impl(ctx, attrs)

def _create_configure_script(configureParameters):
    ctx = configureParameters.ctx
    attrs = configureParameters.attrs
    inputs = configureParameters.inputs

    root = detect_root(ctx.attr.lib_source)
    if len(ctx.attr.working_directory) > 0:
        root = root + "/" + ctx.attr.working_directory

    tools = get_tools_info(ctx)

    # CMake will replace <TARGET> with the actual output file
    flags = get_flags_info(ctx, "<TARGET>")
    no_toolchain_file = ctx.attr.cache_entries.get("CMAKE_TOOLCHAIN_FILE") or not ctx.attr.generate_crosstool_file

    cmake_commands = []

    # If the legacy `make_commands` attribute was not set, use the new
    # `targets` api for building our target.
    if not ctx.attr.make_commands:
        data = ctx.attr.data + getattr(ctx.attr, "tools_deps", [])
        configuration = "Debug" if is_debug_mode(ctx) else "Release"

        # Generate a list of arguments for cmake's build command
        build_args = " ".join([
            ctx.expand_location(arg, data)
            for arg in ctx.attr.build_args
        ])

        # Generate commands for all the targets, ensuring there's
        # always at least 1 call to the default target.
        for target in ctx.attr.targets or [""]:
            # Note that even though directory is always passed, the
            # following arguments can take precedence.
            cmake_commands.append("{cmake} --build {dir} --config {config} {args} {target}".format(
                cmake = attrs.cmake_path,
                dir = ".",
                args = build_args,
                target = target,
                config = configuration,
            ))

        if ctx.attr.install:
            # Generate a list of arguments for cmake's install command
            install_args = " ".join([
                ctx.expand_location(arg, data)
                for arg in ctx.attr.install_args
            ])

            cmake_commands.append("{cmake} --install {dir} --config {config} {args}".format(
                cmake = attrs.cmake_path,
                dir = ".",
                args = install_args,
                config = configuration,
            ))

    define_install_prefix = "export INSTALL_PREFIX=\"" + _get_install_prefix(ctx) + "\"\n"
    configure_script = create_cmake_script(
        workspace_name = ctx.workspace_name,
        cmake_path = configureParameters.attrs.cmake_path,
        tools = tools,
        flags = flags,
        install_prefix = "$$INSTALL_PREFIX$$",
        root = root,
        no_toolchain_file = no_toolchain_file,
        user_cache = dict(ctx.attr.cache_entries),
        user_env = getattr(ctx.attr, "env_vars", {}),
        options = ctx.attr.cmake_options,
        cmake_commands = cmake_commands,
        include_dirs = inputs.include_dirs,
        is_debug_mode = is_debug_mode(ctx),
    )
    return define_install_prefix + configure_script

def _get_install_prefix(ctx):
    if ctx.attr.install_prefix:
        return ctx.attr.install_prefix
    if ctx.attr.lib_name:
        return ctx.attr.lib_name
    return ctx.attr.name

def _attrs():
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
    attrs.update({
        "build_args": attr.string_list(
            doc = "Arguments for the CMake build command",
            mandatory = False,
        ),
        "cache_entries": attr.string_dict(
            doc = (
                "CMake cache entries to initialize (they will be passed with `-Dkey=value`) " +
                "Values, defined by the toolchain, will be joined with the values, passed here. " +
                "(Toolchain values come first)"
            ),
            mandatory = False,
            default = {},
        ),
        "cmake_options": attr.string_list(
            doc = "Arugments for CMake's generate command",
            mandatory = False,
            default = [],
        ),
        "env_vars": attr.string_dict(
            doc = (
                "CMake environment variable values to join with toolchain-defined. " +
                "For example, additional `CXXFLAGS`."
            ),
            mandatory = False,
            default = {},
        ),
        "generate_crosstool_file": attr.bool(
            doc = (
                "When True, CMake crosstool file will be generated from the toolchain values, " +
                "provided cache-entries and env_vars (some values will still be passed as `-Dkey=value` " +
                "and environment variables). If `CMAKE_TOOLCHAIN_FILE` cache entry is passed, " +
                "specified crosstool file will be used When using this option to cross-compile, " +
                "it is required to specify CMAKE_SYSTEM_NAME in the cache_entries"
            ),
            mandatory = False,
            default = True,
        ),
        "install": attr.bool(
            doc = "If True, the `cmake --install` comand will be performed after a build",
            default = True,
        ),
        "install_args": attr.string_list(
            doc = "Arguments for the CMake install command",
            mandatory = False,
        ),
        "install_prefix": attr.string(
            doc = "Relative install prefix to be passed to CMake in `-DCMAKE_INSTALL_PREFIX`",
            mandatory = False,
        ),
        "make_commands": attr.string_list(
            doc = (
                "__deprecated__: Optinal hard coded commands to replace the `cmake --build` commands. It's " +
                "recommended to leave this empty and use the `targets` + `build_args` attributes."
            ),
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
