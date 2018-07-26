load("@bazel_skylib//lib:collections.bzl", "collections")
load("//tools/build_defs:cc_import.bzl", "create_linking_info", "LibrariesToLink")

CC_EXTERNAL_RULE_ATTRIBUTES = {
      "lib_name": attr.string(mandatory = False),
      "lib_source": attr.label(mandatory = True, allow_files = True),
      "defines": attr.string_list(mandatory = False, default = []),
      #
      "additional_inputs": attr.label_list(mandatory = False, allow_files = True, default = []),
      "additional_tools": attr.label_list(mandatory = False, allow_files = True, default = []),
      #
      "postfix_script": attr.string(mandatory = False),
      "make_commands": attr.string_list(mandatory = False, default = ["make", "make install"]),
      #
      "deps": attr.label_list(mandatory = False, allow_files = True, default = []),
      "tools_deps": attr.label_list(mandatory = False, allow_files = True, default = []),
      #
      "out_include_dir": attr.string(mandatory = False, default = "include"),
      "out_lib_dir": attr.string(mandatory = False, default = "lib"),
      "out_bin_dir": attr.string(mandatory = False, default = "bin"),
      #
      "alwayslink": attr.bool(mandatory = False, default = False),
      "static_library": attr.string(mandatory = False),
      "shared_library": attr.string(mandatory = False),
      "interface_library": attr.string(mandatory = False),
      "binaries_names": attr.string_list(mandatory = False, default = []),
      #
      "out_pkg_config_dir": attr.string(mandatory = False),
      "_utils": attr.label(
          default = Label("//tools/build_defs:utils.sh"),
          allow_single_file = True,
          executable = True,
          cfg = "target"
      ),
      "_cc_toolchain": attr.label(default = Label("@bazel_tools//tools/cpp:current_cc_toolchain")),
}

def create_attrs(attr_struct, configure_name, configure_script, **kwargs):
  dict = {}
  for key in CC_EXTERNAL_RULE_ATTRIBUTES:
    if not key.startswith("_") and hasattr(attr_struct, key):
      dict[key] = getattr(attr_struct, key)

  dict["configure_name"] = configure_name
  dict["configure_script"] = configure_script

  for arg in kwargs:
    dict[arg] = kwargs[arg]
  return struct(**dict)

def cc_external_rule_impl(ctx, attrs):
  lib_name = _value(ctx.attr.lib_name, ctx.attr.name)
  outputs = _define_outputs(ctx, lib_name)
  inputs = _define_inputs(ctx, outputs)
  out_cc_info = _define_out_cc_info(ctx, inputs, outputs)

  shell_utils = ctx.attr._utils.files.to_list()[0].path

  script_lines = [
    "set -e",
    "EXT_BUILD_ROOT=$(pwd)",
    "source " + shell_utils,
    "echo \"Building external library '{}'\"".format(lib_name),
    "TMPDIR=$(mktemp -d)",
    "EXT_BUILD_DEPS=$(mktemp -d --tmpdir=$EXT_BUILD_ROOT)",
    "\n".join(_copy_deps_and_tools(inputs)),
    "trap \"{ rm -rf $TMPDIR; }\" EXIT",
    "INSTALLDIR=$EXT_BUILD_ROOT/" + outputs.installdir.path,
    "mkdir -p $INSTALLDIR",
    "echo_vars INSTALLDIR EXT_BUILD_DEPS EXT_BUILD_ROOT PATH",
    "pushd $TMPDIR",
    attrs.configure_script,
    "\n".join(ctx.attr.make_commands),
    _value(ctx.attr.postfix_script, ""),
    "replace_absolute_paths $INSTALLDIR $INSTALLDIR",
    "popd",
  ]

  script_text = '\n'.join(script_lines)

  ctx.actions.run_shell(
          mnemonic="Cc" + attrs.configure_name.capitalize() + "MakeRule",
          inputs = inputs.declared_inputs,
          outputs = outputs.declared_outputs,
          tools = ctx.attr._utils.files,
          use_default_shell_env=True,
          command = script_text,
          execution_requirements = {"block-network": ""}
      )

  return [DefaultInfo(files = depset(direct = outputs.declared_outputs)),
            OutputGroupInfo(gen_dir = depset([outputs.installdir]),
                            bin_dir = depset([outputs.out_bin_dir]),
                            out_binary_files = depset(outputs.out_binary_files),
                            pkg_config_dir = outputs.out_pkg_dir or []),
            cc_common.create_cc_skylark_info(ctx=ctx),
            out_cc_info.compilation_info,
            out_cc_info.linking_info,
]

def _value(value, default_value):
  if (value):
    return value
  return default_value

def _depset(item):
  if item == None:
    return depset()
  return depset([item])

def _list(item):
  if type(item) == list:
    return item
  if item:
    return [item]
  return []

def _copy_deps_and_tools(files):
  list = []
  list += _symlink_to_dir("lib", files.libs, False)
  list += _symlink_to_dir("include", files.headers, True)
  list += _symlink_to_dir("lib/pkgconfig", files.pkg_configs, False)
  list += _symlink_to_dir("bin", files.tools_files, False)

  list += ["define_absolute_paths $EXT_BUILD_ROOT/bin $EXT_BUILD_ROOT/bin"]
  list += ["if [ -d $EXT_BUILD_DEPS/bin ]; then"]
  list += ["  tools=$(find $EXT_BUILD_DEPS/bin -type d,l -maxdepth 1)"]
  list += ["  for tool in $tools; do export PATH=$PATH:$tool; done"]
  list += ["fi"]
  list += ["path $EXT_BUILD_DEPS/bin"]
  list += ["export PKG_CONFIG_PATH=$EXT_BUILD_ROOT/lib/pkgconfig"]

  return list

def _symlink_to_dir(dir_name, files_list, link_children):
  if len(files_list) == 0:
    return []
  list = ["mkdir -p $EXT_BUILD_DEPS/" + dir_name]

  paths_list = []
  for file in files_list:
    paths_list += [file if type(file) == "string" else file.path]

  link_function = "symlink_dir_contents_to_dir" if link_children else "symlink_to_dir"
  for path in paths_list:
    list += ["{} $EXT_BUILD_ROOT/{} $EXT_BUILD_DEPS/{}".format(link_function, path, dir_name)]

  return list

def _check_file_name(var, name):
  if (len(var) == 0):
    fail("{} can not be empty string.".format(name.capitalize()))

  if (not var[0:1].isalpha()):
    fail("{} should start with a letter.".format(name.capitalize()))
  if (not var.isalnum()):
    fail("{} should be alphanumeric.".format(name.capitalize()))

_Outputs = provider(
    doc = "Structure to keep different kinds of the external build outputs",
    fields = dict(
        installdir = "Directory, where the library or binary is installed",
        out_include_dir = "Directory with header files (relative to install directory)",
        out_bin_dir = "Directory with binary files (relative to install directory)",
        out_lib_dir = "Directory with library files (relative to install directory)",
        out_pkg_dir = "Directory with pkgconfig files (relative to install directory)",
        out_binary_files = "Binary files, which will be created by the action",
        libraries = "Library files, which will be created by the action",
        declared_outputs = "All output files and directories of the action",
    )
)

def _define_outputs(ctx, lib_name):
  if (ctx.attr.static_library == None and ctx.attr.dynamic_library == None and ctx.attr.interface_library == None and len(ctx.attr.binaries_names) == 0):
    fail("One of \"out_lib_name\" or \"out_bin_name\" attributes must be provided.")

  _check_file_name(lib_name, "Library name")

  out_binary_files = []
  for file in ctx.attr.binaries_names:
    out_binary_files += [_declare_out(ctx, lib_name, ctx.attr.out_bin_dir, file)]

  out_pkg_dir = None
  if ctx.attr.out_pkg_config_dir:
    out_pkg_dir = ctx.actions.declare_file("/".join([lib_name, ctx.attr.out_pkg_config_dir]))

  installdir = ctx.actions.declare_directory(lib_name)
  out_include_dir = ctx.actions.declare_directory(lib_name + "/" + ctx.attr.out_include_dir)
  out_bin_dir = ctx.actions.declare_directory(lib_name + "/" + ctx.attr.out_bin_dir)
  out_lib_dir = ctx.actions.declare_directory(lib_name + "/" + ctx.attr.out_lib_dir)

  libraries = LibrariesToLink(
                static_library = _declare_out(ctx, lib_name, out_lib_dir, ctx.attr.static_library),
                shared_library = _declare_out(ctx, lib_name, out_lib_dir, ctx.attr.shared_library),
                interface_library = _declare_out(ctx, lib_name, out_lib_dir, ctx.attr.interface_library),
              )
  declared_outputs = [installdir, out_include_dir, out_bin_dir, out_lib_dir] + out_binary_files
  declared_outputs += _list(out_pkg_dir) + _list(libraries.static_library)
  declared_outputs += _list(libraries.shared_library) + _list(libraries.interface_library)

  return _Outputs(
    installdir = installdir,
    out_include_dir = out_include_dir,
    out_bin_dir = out_bin_dir,
    out_lib_dir = out_lib_dir,
    out_pkg_dir = out_pkg_dir,
    out_binary_files = out_binary_files,
    libraries = libraries,
    declared_outputs = declared_outputs,
  )

def _define_inputs(ctx, outputs):
  pkg_configs = []
  compilation_infos = []
  linking_infos = []

  for dep in ctx.attr.deps:
    compilation_infos += [dep[CcCompilationInfo]]
    linking_infos += [dep[CcLinkingInfo]]

    provider = dep[OutputGroupInfo]
    if provider and hasattr(provider, "pkg_config_dir"):
      # or do we want to be able to produce several files?
      pkg_configs += provider.pkg_config_dir.to_list()

  tools_roots = []
  tools_files = []
  for tool in ctx.attr.tools_deps:
    tool_root = detect_root(tool)
    tools_roots += [tool_root]
    for file_list in tool.files.to_list():
      tools_files += _list(file_list)

  for tool in ctx.attr.additional_tools:
    for file_list in tool.files.to_list():
      tools_files += _list(file_list)

  deps_compilation = cc_common.merge_cc_compilation_infos(cc_compilation_infos = compilation_infos)
  deps_linking = cc_common.merge_cc_linking_infos(cc_linking_infos = linking_infos)

  (libs, link_opts) = _collect_libs_and_flags(deps_linking)
  headers = [] + deps_compilation.system_includes.to_list()

  return struct(
        headers = headers,
        libs = libs,
        # todo do we pass link opts to cmake or to make????
        link_opts = link_opts,
        tools_files = tools_roots,
        pkg_configs = pkg_configs,
        deps_compilation_info = deps_compilation,
        deps_linking_info = deps_linking,
        declared_inputs = depset(ctx.attr.lib_source.files) + libs + tools_files + pkg_configs + ctx.attr.additional_inputs + deps_compilation.headers
)

def _define_out_cc_info(ctx, inputs, outputs):
  compilation_info = CcCompilationInfo(headers = depset([outputs.out_include_dir]),
                                       system_includes = depset([outputs.out_include_dir.path]),
                                       defines = depset(ctx.attr.defines))
  out_compilation_info = cc_common.merge_cc_compilation_infos(
      cc_compilation_infos = [inputs.deps_compilation_info, compilation_info])

  linking_info = create_linking_info(ctx, outputs.libraries)
  out_linking_info = cc_common.merge_cc_linking_infos(
      cc_linking_infos = [inputs.deps_linking_info, linking_info])

  return struct(
      compilation_info = out_compilation_info,
      linking_info = out_linking_info
  )

def _collect_libs_and_flags(cc_linking):
  libs = []
  link_opts = []

  for params in [cc_linking.static_mode_params_for_dynamic_library,
                                   cc_linking.static_mode_params_for_executable,
                                   cc_linking.dynamic_mode_params_for_dynamic_library,
                                   cc_linking.dynamic_mode_params_for_executable]:
    libs += [lib.artifact() for lib in params.libraries_to_link.to_list()]
    libs += params.dynamic_libraries_for_runtime.to_list()
    link_opts = params.linkopts.to_list()

  return (collections.uniq(libs), collections.uniq(link_opts))

def _declare_out(ctx, lib_name, dir, file):
  if file:
    return ctx.actions.declare_file("/".join([lib_name, dir.basename, file]))
  return None

# public!
def define_flags(ctx):
  cpp_fragment = ctx.fragments.cpp
  compiler_options = [] # todo from toolchain provider

  return {
    "CFLAGS": _strings_into_flags(compiler_options + cpp_fragment.c_options, " "),
    "CXXFLAGS": _strings_into_flags(compiler_options + cpp_fragment.cxx_options(ctx.features), " "),
    "LDFLAGS": "-L$EXT_BUILD_DEPS/lib",
    "CPPFLAGS": "-I$EXT_BUILD_DEPS/include",
  }

def _strings_into_flags(list, separator):
  return separator.join([elem for elem in list])

def join_flags_string(flags_dict):
  return " ".join([key + "=\"" + flags_dict[key] + "\""
    for key in flags_dict.keys() if len(flags_dict[key]) > 0])

def detect_root(ctx):
  root = ctx.attr.lib_source.label.workspace_root
  sources = ctx.attr.lib_source.files
  if (not root or len(root) == 0) and len(sources) > 0:
    root = ""
    # find topmost directory
    for file in sources:
      if len(root) == 0 or len(root) > len(file.path):
        root = file.path
  return root