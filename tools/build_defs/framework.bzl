load("@bazel_skylib//lib:collections.bzl", "collections")
load("//tools/build_defs:cc_import.bzl", "create_linking_info")

CC_EXTERNAL_RULE_ATTRIBUTES = dict({
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
})

def cc_external_rule_impl(ctx, configure_name, configure_script):
  lib_name = _value(ctx.attr.lib_name, ctx.attr.name)
  out_files = _define_outputs(ctx, lib_name)
  (configure_params, cc_info) = _define_inputs(ctx, out_files)

  shell_utils = ctx.attr._utils.files.to_list()[0].path

  script_lines = [
    "set -e",
    "EXT_BUILD_ROOT=$(pwd)",
    "source " + shell_utils,
    "echo \"Building external library '{}'\"".format(lib_name),
    "TMPDIR=$(mktemp -d)",
    "EXT_BUILD_DEPS=$(mktemp -d --tmpdir=$EXT_BUILD_ROOT)",
    "\n".join(_copy_deps_and_tools(configure_params)),
    "trap \"{ rm -rf $TMPDIR; }\" EXIT",
    "INSTALLDIR=$EXT_BUILD_ROOT/" + out_files.wrapper.path,
    "mkdir -p $INSTALLDIR",
    "echo_vars INSTALLDIR EXT_BUILD_DEPS EXT_BUILD_ROOT",
    "pushd $TMPDIR",
    configure_script,
    "\n".join(ctx.attr.make_commands),
    _value(ctx.attr.postfix_script, ""),
    "replace_absolute_paths $INSTALLDIR $INSTALLDIR",
    "popd",
  ]

  script_text = '\n'.join(script_lines)

  ctx.actions.run_shell(
          mnemonic="Cc" + configure_name.capitalize() + "MakeRule",
          inputs = configure_params.declared_inputs,
          outputs = out_files.declared_outputs,
          tools = ctx.attr._utils.files,
          use_default_shell_env=True,
          command = script_text,
          execution_requirements = {"block-network": ""}
      )

  return [DefaultInfo(files = depset(direct = out_files.declared_outputs)),
            OutputGroupInfo(gen_dir = depset([out_files.wrapper]),
                            bin_dir = depset([out_files.out_bin_dir]),
                            out_binary_files = depset(out_files.out_binary_files),
                            pkg_config_dir = out_files.out_pkg_dir or []),
            cc_common.create_cc_skylark_info(ctx=ctx),
            cc_info.compilation_info,
            cc_info.linking_info,
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
  if item:
    return [item]
  return []

def _copy_deps_and_tools(files):
  list = ["mkdir -p " + cmd for cmd in
      ["$EXT_BUILD_DEPS/lib", "$EXT_BUILD_DEPS/include", "$EXT_BUILD_DEPS/lib/pkgconfig"]]
  groups = {
      "lib": files.libs,
      "include": files.headers,
      "lib/pkgconfig": files.pkg_configs,
      "bin": files.tools_files,
  }
  for key in groups.keys():
    for file in groups[key]:
      if (type(file) == "string"):
        list += ["copy_to_dir $EXT_BUILD_ROOT/{} $EXT_BUILD_DEPS/{}".format(file, key)]
      else:
        list += ["copy_to_dir $EXT_BUILD_ROOT/{} $EXT_BUILD_DEPS/{}".format(file.path, key)]

  list += ["define_absolute_paths $EXT_BUILD_ROOT/bin $EXT_BUILD_ROOT/bin"]
  list += ["path $EXT_BUILD_ROOT/bin"]
  list += ["export PKG_CONFIG_PATH=$EXT_BUILD_ROOT/lib/pkgconfig"]
  return list

def _check_file_name(var, name):
  if (len(var) == 0):
    fail("{} can not be empty string.".format(name.capitalize()))

  if (not var[0:1].isalpha()):
    fail("{} should start with a letter.".format(name.capitalize()))
  if (not var.isalnum()):
    fail("{} should be alphanumeric.".format(name.capitalize()))

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

  wrapper = ctx.actions.declare_directory(lib_name)
  out_include_dir = ctx.actions.declare_directory(lib_name + "/" + ctx.attr.out_include_dir)
  out_bin_dir = ctx.actions.declare_directory(lib_name + "/" + ctx.attr.out_bin_dir)
  out_lib_dir = ctx.actions.declare_directory(lib_name + "/" + ctx.attr.out_lib_dir)

  libraries = struct(
                static_library = _declare_out(ctx, lib_name, out_lib_dir, ctx.attr.static_library),
                shared_library = _declare_out(ctx, lib_name, out_lib_dir, ctx.attr.shared_library),
                interface_library = _declare_out(ctx, lib_name, out_lib_dir, ctx.attr.interface_library),
              )
  declared_outputs = [wrapper, out_include_dir, out_bin_dir, out_lib_dir] + out_binary_files
  declared_outputs += _list(out_pkg_dir) + _list(libraries.static_library)
  declared_outputs += _list(libraries.shared_library) + _list(libraries.interface_library)

  return struct(
    wrapper = wrapper,
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

  tools_files = []
  for tool in ctx.attr.tools_deps:
    for file_list in tool.files.to_list():
      tools_files += file_list
  tools_files += ctx.attr.additional_tools

  deps_compilation = cc_common.merge_cc_compilation_infos(cc_compilation_infos = compilation_infos)
  compilation_info = CcCompilationInfo(headers = depset([outputs.out_include_dir]), system_includes = depset([outputs.out_include_dir.path]), defines = depset(ctx.attr.defines))
  out_compilation_info = cc_common.merge_cc_compilation_infos(cc_compilation_infos = [deps_compilation, compilation_info])

  deps_linking = cc_common.merge_cc_linking_infos(cc_linking_infos = linking_infos)
  out_lib_dir = ctx.attr.out_lib_dir
  linking_info = create_linking_info(ctx, outputs.libraries)
  out_linking_info = cc_common.merge_cc_linking_infos(cc_linking_infos = [deps_linking, linking_info])

  (libs, link_opts) = _collect_libs_and_flags(deps_linking)

  headers = []
  for header in deps_compilation.headers:
    headers += [header]
  for header in deps_compilation.system_includes:
    headers += [header]

  return (
    struct(
        headers = headers,
        libs = libs,
        # todo do we pass link opts to cmake or to make????
        link_opts = link_opts,
        tools_files = tools_files,
        pkg_configs = pkg_configs,
        declared_inputs = depset(ctx.attr.lib_source.files) + libs + tools_files + pkg_configs + ctx.attr.additional_inputs
    ),
    struct(
      compilation_info = out_compilation_info,
      linking_info = out_linking_info
    )
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
  if not root or len(root) == 0:
    for file in ctx.attr.lib_source.files:
      root = file.path
      print(root)
      break
  return root
