""" Defines the rule for building external library with CMake
"""

load("//tools/build_defs:framework.bzl", "cc_external_rule_impl", "detect_root",
   "CC_EXTERNAL_RULE_ATTRIBUTES", "create_attrs")

def _cmake_external(ctx):
  options = " ".join(ctx.attr.cmake_options)
  root = detect_root(ctx.attr.lib_source)
  cmake_string = "cmake -DCMAKE_PREFIX_PATH=\"$EXT_BUILD_ROOT\" -DCMAKE_INSTALL_PREFIX=$INSTALLDIR {} $EXT_BUILD_ROOT/{}".format(options, root)

  attrs = create_attrs(ctx.attr,
                       configure_name = 'CMake',
                       configure_script = cmake_string)

  return cc_external_rule_impl(ctx, attrs)

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
