""" Defines the rule for building external library with CMake
"""

load(
    "//tools/build_defs:framework.bzl",
    "CC_EXTERNAL_RULE_ATTRIBUTES",
    "cc_external_rule_impl",
    "create_attrs",
    "detect_root",
)
load("//tools/build_defs:cc_toolchain_util.bzl", "absolutize_path_in_str", "getFlagsInfo", "getToolsInfo")

CMAKE_TOOLCHAIN_ENV_VARS = [
    "CC",
    "CXX",
    "CFLAGS",
    "CXXFLAGS",
    "CXXFLAGS",
    "ASMFLAGS",
]

CMAKE_TOOLCHAIN_OPTIONS = [
    "CMAKE_AR",
    "CMAKE_CXX_LINK_EXECUTABLE",
    "CMAKE_SHARED_LINKER_FLAGS",
    "CMAKE_EXE_LINKER_FLAGS",
]

def _cmake_external(ctx):
    options = " ".join(ctx.attr.cmake_options)
    root = detect_root(ctx.attr.lib_source)

    tools = getToolsInfo(ctx)
    flags = getFlagsInfo(ctx)

    install_prefix = ctx.attr.install_prefix
    install_prefix = install_prefix if install_prefix else ctx.attr.lib_name
    install_prefix = install_prefix if install_prefix else ctx.attr.name

    cmake_string = " ".join([
        " ".join(_get_toolchain_variables(ctx, tools, flags)),
        " cmake",
        " ".join(_get_toolchain_options(ctx, tools, flags)),
        "-DCMAKE_PREFIX_PATH=\"$EXT_BUILD_ROOT\"",
        "-DCMAKE_INSTALL_PREFIX=\"{}\"".format(install_prefix),
        options,
        "$EXT_BUILD_ROOT/" + root,
    ])
    copy_results = "copy_dir_contents_to_dir $TMPDIR/{} $INSTALLDIR".format(install_prefix)

    attrs = create_attrs(
        ctx.attr,
        configure_name = "CMake",
        configure_script = cmake_string,
        postfix_script = copy_results + "\n" + ctx.attr.postfix_script,
    )

    return cc_external_rule_impl(ctx, attrs)

def _get_toolchain_variables(ctx, tools, flags):
    vars = {}

    if tools.cc:
        vars["CC"] = [tools.cc]
    if tools.cxx:
        vars["CXX"] = [tools.cxx]
    if flags.cc:
        vars["CFLAGS"] = flags.cc
    if flags.cc:
        vars["CXXFLAGS"] = flags.cxx
    if flags.assemble:
        vars["ASMFLAGS"] = flags.assemble

    string_list = []
    for key in ctx.attr.cmake_variable_from_toolchain:
        value = vars[key]
        if value:
            string_list += _env_var(ctx, key, value)
    return string_list

def _get_toolchain_options(ctx, tools, flags):
    options = {}
    if tools.cxx_linker_static:
        options["CMAKE_AR"] = [tools.cxx_linker_static]

    # this does not work by some reason
    #        options += _option(ctx, "CMAKE_CXX_CREATE_STATIC_LIBRARY", ["<CMAKE_AR> <LINK_FLAGS> qc <TARGET> <OBJECTS>"])
    #        options += _option(ctx, "CMAKE_CXX_ARCHIVE_CREATE", ["<CMAKE_AR> <LINK_FLAGS> qc <TARGET> <OBJECTS>"])
    #        options += _option(ctx, "CMAKE_CXX_ARCHIVE_APPEND", ["<CMAKE_AR> <LINK_FLAGS> qc <TARGET> <OBJECTS>"])
    #        options += _option(ctx, "CMAKE_CXX_ARCHIVE_FINISH", ["<CMAKE_RANLIB> <TARGET>"])

    if tools.cxx_linker_executable:
        # https://github.com/Kitware/CMake/blob/master/Modules/CMakeCXXInformation.cmake
        rule_string = " ".join([
            "{}",
            "<FLAGS>",
            "<CMAKE_CXX_LINK_FLAGS>",
            "<LINK_FLAGS>",
            "<OBJECTS>",
            "-o <TARGET>",
            "<LINK_LIBRARIES>",
        ]).format(absolutize_path_in_str(ctx, tools.cxx_linker_executable, "$EXT_BUILD_ROOT/"))
        options["CMAKE_CXX_LINK_EXECUTABLE"] = [rule_string]

    # commented out for now, because http://cmake.3232098.n2.nabble.com/CMake-incorrectly-passes-linker-flags-to-ar-td7592436.html
    #    if flags.cxx_linker_static:
    #        options += _option(ctx, "CMAKE_STATIC_LINKER_FLAGS", flags.cxx_linker_static)
    if flags.cxx_linker_shared:
        options["CMAKE_SHARED_LINKER_FLAGS"] = flags.cxx_linker_shared
    if flags.cxx_linker_executable:
        options["CMAKE_EXE_LINKER_FLAGS"] = flags.cxx_linker_executable

    string_list = []
    for key in ctx.attr.cmake_options_from_toolchain:
        value = options[key]
        if value:
            string_list += _option(ctx, key, value)
    return string_list

def _env_var(ctx, cmake_option, flags):
    return ["{}=\"{}\"".format(cmake_option, _join_flags_list(ctx, flags))]

def _option(ctx, cmake_option, flags):
    return ["-D{}=\"{}\"".format(cmake_option, _join_flags_list(ctx, flags))]

def _join_flags_list(ctx, flags):
    return " ".join([absolutize_path_in_str(ctx, flag, "$EXT_BUILD_ROOT/") for flag in flags])

def _attrs():
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
    attrs.update({
        # Relative install prefix to be passed to CMake in -DCMAKE_INSTALL_PREFIX
        "install_prefix": attr.string(mandatory = False),
        # Other CMake options
        "cmake_options": attr.string_list(mandatory = False, default = []),
        # The list of environment variables to be set from Bazel C/C++ toolchain,
        # should be subset of CMAKE_TOOLCHAIN_ENV_VARS, default CMAKE_TOOLCHAIN_ENV_VARS
        "cmake_variable_from_toolchain": attr.string_list(mandatory = False, default = CMAKE_TOOLCHAIN_ENV_VARS),
        # The list of CMake options to be set from Bazel C/C++ toolchain,
        # should be subset of CMAKE_TOOLCHAIN_OPTIONS, default CMAKE_TOOLCHAIN_OPTIONS
        "cmake_options_from_toolchain": attr.string_list(mandatory = False, default = CMAKE_TOOLCHAIN_OPTIONS),
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
