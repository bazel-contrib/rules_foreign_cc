""" Defines the rule for building external library with CMake
"""

load(
    "//tools/build_defs:framework.bzl",
    "CC_EXTERNAL_RULE_ATTRIBUTES",
    "cc_external_rule_impl",
    "create_attrs",
    "detect_root",
)
load("//tools/build_defs:cc_linking_util.bzl", "absolutize_path_in_str", "getFlagsInfo", "getToolsInfo")

def _cmake_external(ctx):
    options = " ".join(ctx.attr.cmake_options)
    root = detect_root(ctx.attr.lib_source)

    tools = getToolsInfo(ctx)
    flags = getFlagsInfo(ctx)

    cmake_string = " ".join([
        " ".join(_get_toolchain_variables(ctx, tools, flags)),
        " cmake",
        " ".join(_get_toolchain_options(ctx, tools, flags)),
        "-DCMAKE_PREFIX_PATH=\"$EXT_BUILD_ROOT\"",
        "-DCMAKE_INSTALL_PREFIX=$INSTALLDIR",
        options,
        "$EXT_BUILD_ROOT/" + root,
    ])

    attrs = create_attrs(
        ctx.attr,
        configure_name = "CMake",
        configure_script = cmake_string,
    )

    return cc_external_rule_impl(ctx, attrs)

def _get_toolchain_variables(ctx, tools, flags):
    vars = []

    if tools.cc:
        vars += _env_var(ctx, "CC", [tools.cc])
    if tools.cxx:
        vars += _env_var(ctx, "CXX", [tools.cxx])
    if flags.cc:
        vars += _env_var(ctx, "CFLAGS", flags.cc)
    if flags.cc:
        vars += _env_var(ctx, "CXXFLAGS", flags.cxx)
    if flags.assemble:
        vars += _env_var(ctx, "ASMFLAGS", flags.assemble)
    return vars

def _get_toolchain_options(ctx, tools, flags):
    options = []
    if tools.cxx_linker_shared:
        # https://github.com/Kitware/CMake/blob/master/Modules/CMakeCXXInformation.cmake
        rule_string = " ".join([
            "{}",
            "<CMAKE_SHARED_LIBRARY_CXX_FLAGS>",
            "<LANGUAGE_COMPILE_FLAGS>",
            "<LINK_FLAGS>",
            "<CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS>",
            "<SONAME_FLAG><TARGET_SONAME>",
            "-o <TARGET>",
            "<OBJECTS>",
            "<LINK_LIBRARIES>",
        ]).format(absolutize_path_in_str(ctx, tools.cxx_linker_shared, "$EXT_BUILD_ROOT/"))
        options += _option(ctx, "CMAKE_CXX_CREATE_SHARED_LIBRARY", [rule_string])
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
        options += _option(ctx, "CMAKE_CXX_LINK_EXECUTABLE", [rule_string])

    if flags.cxx_linker_static:
        options += _option(ctx, "CMAKE_STATIC_LINKER_FLAGS", flags.cxx_linker_static)
    if flags.cxx_linker_shared:
        options += _option(ctx, "CMAKE_SHARED_LINKER_FLAGS", flags.cxx_linker_shared)
    if flags.cxx_linker_executable:
        options += _option(ctx, "CMAKE_EXE_LINKER_FLAGS", flags.cxx_linker_executable)

    return options

def _env_var(ctx, cmake_option, flags):
    return ["{}=\"{}\"".format(cmake_option, _join_flags_list(ctx, flags))]

def _option(ctx, cmake_option, flags):
    return ["-D{}=\"{}\"".format(cmake_option, _join_flags_list(ctx, flags))]

def _join_flags_list(ctx, flags):
    return " ".join([absolutize_path_in_str(ctx, flag, "$EXT_BUILD_ROOT/") for flag in flags])

def _attrs():
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
    attrs.update({"cmake_options": attr.string_list(mandatory = False, default = [])})
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
