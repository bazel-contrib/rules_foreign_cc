load("//tools/build_defs:framework.bzl", "cc_external_rule_impl", "detect_root", "CC_EXTERNAL_RULE_ATTRIBUTES")

def _cmake_external(ctx):
  options = " ".join(ctx.attr.cmake_options)
  root = detect_root(ctx)
  cmake_string = "cmake -DCMAKE_PREFIX_PATH=\"$EXT_BUILD_ROOT\" -DCMAKE_INSTALL_PREFIX=$INSTALLDIR {} $EXT_BUILD_ROOT/{}".format(options, root)

  return cc_external_rule_impl(
      ctx,
      configure_name = 'CMake',
      configure_script = cmake_string
  )

def _attrs():
  attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
  attrs["cmake_options"] = attr.string_list(mandatory = False, default = [])
  return attrs

cmake_external = rule(
    attrs = _attrs(),
    fragments = ["cpp"],
    output_to_genfiles = True,
    implementation = _cmake_external
)
