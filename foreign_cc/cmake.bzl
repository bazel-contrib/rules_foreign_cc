""" Defines the rule for building external library with CMake
"""

load(
    "//foreign_cc/private:cc_toolchain_util.bzl",
    "get_flags_info",
    "get_tools_info",
    "is_debug_mode",
)
load("//foreign_cc/private:cmake_script.bzl", "create_cmake_script")
load("//foreign_cc/private:detect_root.bzl", "detect_root")
load(
    "//foreign_cc/private:framework.bzl",
    "CC_EXTERNAL_RULE_ATTRIBUTES",
    "CC_EXTERNAL_RULE_FRAGMENTS",
    "cc_external_rule_impl",
    "create_attrs",
)
load(
    "//foreign_cc/private:shell_script_helper.bzl",
    "os_name",
)
load(
    "//toolchains/native_tools:tool_access.bzl",
    "get_cmake_data",
    "get_make_data",
    "get_ninja_data",
)

def _cmake_impl(ctx):
    cmake_data = get_cmake_data(ctx)

    tools_deps = ctx.attr.tools_deps + cmake_data.deps
    env = dict(ctx.attr.env)

    generator, generate_args = _get_generator_target(ctx)
    if "Unix Makefiles" == generator:
        make_data = get_make_data(ctx)
        tools_deps.extend(make_data.deps)
        generate_args.append("-DCMAKE_MAKE_PROGRAM={}".format(make_data.path))
    elif "Ninja" in generator:
        ninja_data = get_ninja_data(ctx)
        tools_deps.extend(ninja_data.deps)
        generate_args.append("-DCMAKE_MAKE_PROGRAM={}".format(ninja_data.path))

    attrs = create_attrs(
        ctx.attr,
        env = env,
        generator = generator,
        generate_args = generate_args,
        configure_name = "CMake",
        create_configure_script = _create_configure_script,
        tools_deps = tools_deps,
        cmake_path = cmake_data.path,
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
        # There's no need to use the `--target` argument for an empty/"all" target
        if target:
            target = "--target '{}'".format(target)

        # Note that even though directory is always passed, the
        # following arguments can take precedence.
        cmake_commands.append("{cmake} --build {dir} --config {config} {target} {args}".format(
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

    configure_script = create_cmake_script(
        workspace_name = ctx.workspace_name,
        generator = attrs.generator,
        cmake_path = attrs.cmake_path,
        tools = tools,
        flags = flags,
        install_prefix = "$$INSTALLDIR$$",
        root = root,
        no_toolchain_file = no_toolchain_file,
        user_cache = dict(ctx.attr.cache_entries),
        user_env = getattr(ctx.attr, "env_vars", {}),
        options = attrs.generate_args,
        cmake_commands = cmake_commands,
        include_dirs = inputs.include_dirs,
        is_debug_mode = is_debug_mode(ctx),
    )
    return configure_script

def _get_generator_target(ctx):
    """Parse the genrator arguments for a generator declaration

    If none is found, a default will be chosen

    Args:
        ctx (ctx): The rule's context object

    Returns:
        tuple: (str, list) the generator and a list of arguments with the generator arg removed
    """
    known_generators = [
        "Borland Makefiles",
        "Green Hills MULTI",
        "MinGW Makefiles",
        "MSYS Makefiles",
        "Ninja",
        "Ninja Multi-Config",
        "NMake Makefiles JOM",
        "NMake Makefiles",
        "Unix Makefiles",
        "Visual Studio 10 2010",
        "Visual Studio 11 2012",
        "Visual Studio 12 2013",
        "Visual Studio 14 2015",
        "Visual Studio 15 2017",
        "Visual Studio 16 2019",
        "Visual Studio 9 2008",
        "Watcom WMake",
        "Xcode",
    ]

    generator = None

    generator_definitions = []

    # Create a mutable list
    generate_args = list(ctx.attr.generate_args)
    for arg in generate_args:
        if arg.startswith("-G"):
            generator_definitions.append(arg)
            break

    if len(generator_definitions) > 1:
        fail("Please specify no more than 1 generator argument. Arguments found: {}".format(generator_definitions))

    for definition in generator_definitions:
        generator = definition[2:]
        generator = generator.strip(" =\"'")

        # Remove the argument so it's not passed twice to the cmake command
        # See create_cmake_script for more details
        generate_args.remove(definition)

    if not generator:
        execution_os_name = os_name(ctx)
        if "win" in execution_os_name:
            generator = "Ninja"
        elif "macos" in execution_os_name:
            generator = "Unix Makefiles"
        elif "linux" in execution_os_name:
            generator = "Unix Makefiles"
        else:
            fail("No generator set and no default is known. Please set the cmake `generator` attribute")

    # Sanity check
    for gen in known_generators:
        if generator.startswith(gen):
            return generator, generate_args

    fail("`{}` is not a known generator".format(generator))

def _attrs():
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
    attrs.pop("make_commands")
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
        "env_vars": attr.string_dict(
            doc = (
                "CMake environment variable values to join with toolchain-defined. " +
                "For example, additional `CXXFLAGS`."
            ),
            mandatory = False,
            default = {},
        ),
        "generate_args": attr.string_list(
            doc = (
                "Arguments for CMake's generate command. Arguments should be passed as key/value pairs. eg: " +
                "`[\"-G Ninja\", \"--debug-output\", \"-DFOO=bar\"]`. Note that unless a generator (`-G`) argument " +
                "is provided, the default generators are [Unix Makefiles](https://cmake.org/cmake/help/latest/generator/Unix%20Makefiles.html) " +
                "for Linux and MacOS and [Ninja](https://cmake.org/cmake/help/latest/generator/Ninja.html) for " +
                "Windows."
            ),
            mandatory = False,
            default = [],
        ),
        "generate_crosstool_file": attr.bool(
            doc = (
                "When True, CMake crosstool file will be generated from the toolchain values, " +
                "provided cache-entries and env_vars (some values will still be passed as `-Dkey=value` " +
                "and environment variables). If `CMAKE_TOOLCHAIN_FILE` cache entry is passed, " +
                "specified crosstool file will be used When using this option to cross-compile, " +
                "it is required to specify `CMAKE_SYSTEM_NAME` in the cache_entries"
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
    # TODO: Remove once https://github.com/bazelbuild/bazel/issues/11584 is closed and the min supported
    # version is updated to a release of Bazel containing the new default for this setting.
    incompatible_use_toolchain_transition = True,
)
