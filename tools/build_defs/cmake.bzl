""" Defines the rule for building external library with CMake
"""

load("//tools/build_defs:framework.bzl", "cc_external_rule_impl", "detect_root",
   "CC_EXTERNAL_RULE_ATTRIBUTES", "create_attrs")
load("//tools/build_defs:cc_linking_util.bzl", "getToolsInfo", "getFlagsInfo")

def _cmake_external(ctx):
  options = " ".join(ctx.attr.cmake_options)
  root = detect_root(ctx.attr.lib_source)

  cmake_string = " ".join([
    "cmake",
    " ".join(_get_toolchain_options(ctx)),
    "-DCMAKE_PREFIX_PATH=\"$EXT_BUILD_ROOT\"",
    "-DCMAKE_INSTALL_PREFIX=$INSTALLDIR",
    options,
    "$EXT_BUILD_ROOT/" + root
  ])

  attrs = create_attrs(ctx.attr,
                       configure_name = 'CMake',
                       configure_script = cmake_string)

  return cc_external_rule_impl(ctx, attrs)

def _get_toolchain_options(ctx):
  tools = getToolsInfo(ctx)
  flags = getFlagsInfo(ctx)

  options = []
  if tools.cc:
    options += ["-DCC=" + tools.cc]
  if tools.cxx:
    options += ["-DCXX=" + tools.cxx]
  if tools.cxx_linker_static:
    options += ["-DCMAKE_CXX_LINK_EXECUTABLE=\"{} <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS>  -o <TARGET> <LINK_LIBRARIES>\"".format(tools.cxx_linker_static)]

  if flags.cc:
    options += _flags("CFLAGS", flags.cc)
  if flags.cc:
    options += _flags("CXXFLAGS", flags.cxx)

  if flags.cxx_linker_static:
    options += _flags("STATIC_LIBRARY_FLAGS", flags.cxx_linker_static)
  if flags.cxx_linker_shared:
    options += _flags("CMAKE_SHARED_LINKER_FLAGS", flags.cxx_linker_shared)
  if flags.cxx_linker_executable:
    options += _flags("CMAKE_EXE_LINKER_FLAGS", flags.cxx_linker_executable)

  if flags.assemble:
    options += _flags("ASMFLAGS", flags.assemble)

  return options

def _flags(cmake_option, flags):
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
