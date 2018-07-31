""" Defines the rule for building external library with CMake
"""

load("//tools/build_defs:framework.bzl", "cc_external_rule_impl", "detect_root",
   "CC_EXTERNAL_RULE_ATTRIBUTES", "create_attrs")
load("//tools/build_defs:cc_linking_util.bzl", "getToolsInfo", "getFlagsInfo")

def _cmake_external(ctx):
  options = " ".join(ctx.attr.cmake_options)
  root = detect_root(ctx.attr.lib_source)

  tools = getToolsInfo(ctx)
  flags = getFlagsInfo(ctx)

  cmake_string = " ".join([
    " ".join(_get_toolchain_variables(tools, flags)),
    " cmake",
    " ".join(_get_toolchain_options(tools, flags)),
    "-DCMAKE_PREFIX_PATH=\"$EXT_BUILD_ROOT\"",
    "-DCMAKE_INSTALL_PREFIX=$INSTALLDIR",
    options,
    "$EXT_BUILD_ROOT/" + root
  ])

  attrs = create_attrs(ctx.attr,
                       configure_name = 'CMake',
                       configure_script = cmake_string)

  return cc_external_rule_impl(ctx, attrs)

def _get_toolchain_variables(tools, flags):
  vars = []
  if tools.cc:
    vars += _env_var("CC", [tools.cc])
  if tools.cxx:
    vars += _env_var("CXX", [tools.cxx])
  if flags.cc:
    vars += _env_var("CFLAGS", flags.cc)
  if flags.cc:
    vars += _env_var("CXXFLAGS", flags.cxx)
  if flags.assemble:
    vars += _env_var("ASMFLAGS", flags.assemble)
  return vars

def _get_toolchain_options(tools, flags):
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
        "<LINK_LIBRARIES>"
        ]).format(tools.cxx_linker_shared)
    options += _option("CMAKE_CXX_CREATE_SHARED_LIBRARY", [rule_string])
  if tools.cxx_linker_executable:
    # https://github.com/Kitware/CMake/blob/master/Modules/CMakeCXXInformation.cmake
    rule_string = "{} <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS>  -o <TARGET> <LINK_LIBRARIES>".format(tools.cxx_linker_executable)
    options += _option("CMAKE_CXX_LINK_EXECUTABLE", [rule_string])

  if flags.cxx_linker_static:
    options += _option("CMAKE_STATIC_LINKER_FLAGS", flags.cxx_linker_static)
  if flags.cxx_linker_shared:
    options += _option("CMAKE_SHARED_LINKER_FLAGS", flags.cxx_linker_shared)
  if flags.cxx_linker_executable:
    options += _option("CMAKE_EXE_LINKER_FLAGS", flags.cxx_linker_executable)

  return options

def _env_var(cmake_option, flags):
  return ["{}=\"{}\"".format(cmake_option, " ".join(flags))]

def _option(cmake_option, flags):
  return ["-D{}=\"{}\"".format(cmake_option, " ".join(flags))]

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
    implementation = _cmake_external
)
