def _cc_configure_make(ctx):
    files = define_files(ctx)

    inputs = ctx.attr.srcs.files + files.all_deps
    outputs = [files.wrapper, files.out_includes_folder, files.out_lib_folder, files.out_lib_file]
    pkg_configs = depset()
    if files.out_pkg_folder:
      outputs += [files.out_pkg_folder]
      pkg_configs = depset([files.out_pkg_folder])
    parameters = define_parameters(ctx, files)
    flags = join_flags_string(parameters.flags)

    cp_cmd = ""
    for key in files.deps.keys():
      deps = files.deps[key]
      cp_cmd += "\nmkdir $tmplib/{} $tmplib/{}/lib\nmkdir $tmplib/{}/include\nmkdir $tmplib/{}/lib/pkgconfig\n".format(
          key, key, key, key
      )
      cp_cmd += "\n" + "\n".join(["cp -r $P/{} $tmplib/{}/lib".format(file.path, key) for file in deps.deps_libs])
      cp_cmd += "\n" + "\n".join(["cp -r $P/{}/* $tmplib/{}/include".format(file.path, key) for file in deps.deps_headers])

      cp_cmd += "\n" + "\n".join(["cp -r $P/{}/* $tmplib/{}/lib/pkgconfig".format(file.path, key) for file in deps.deps_pkgs])
      cp_cmd += "\n"
      cp_cmd += "\n".join(["find $tmplib/{}/lib/pkgconfig -type f -exec sed -i 's@'\"$P/\"'".format(key)
       + files.wrapper.dirname + "@'\"$tmplib\"'@g' {} ';'" for file in deps.deps_pkgs])

    print("CP_CMD: " + cp_cmd)
    print("FLAGS: " + flags)

    configure_string = flags + " $P/{}/configure --prefix=$P/$installdir {}".format(
      ctx.attr.srcs.label.workspace_root, parameters.processed_configure_params)
    make_string = flags + " make install"

    print("Configure: " + configure_string)

    command = [
            "set -e",
            "echo '" + files.wrapper.basename + "'",
            "P=$(pwd)",
            "tmpdir=$(mktemp -d)",
            "installdir=" + files.wrapper.path,
            "tmplib=$(mktemp -d --tmpdir=$P)",

            "echo 'P: ' $P",
            "echo 'tmpdir: ' $tmpdir",
            "echo 'tmplib: ' $tmplib",

            cp_cmd,
            "trap \"{ rm -rf $tmpdir; }\" EXIT",
            "pushd $tmpdir",
            "echo --- START CONFIGURE: " + configure_string,
            "export PKG_CONFIG_PATH=" + parameters.flags["PKG_CONFIG_PATH"],
            "echo 'PKG_CONFIG_PATH=' $PKG_CONFIG_PATH",
            configure_string,
            "echo --- END CONFIGURE",
            "echo --- START MAKE INSTALL " + ctx.attr.name,

            make_string,
            "echo --- END MAKE INSTALL",
            "popd",
            ]
    if (not ctx.attr.trace):
      tmp_command = []
      for line in command:
        if not line.startswith("echo"):
          tmp_command += [line]
      command = tmp_command

    ctx.actions.run_shell(
        mnemonic="CcConfigureMake",
        inputs = inputs,
        outputs = outputs,
        use_default_shell_env=True,
        command = '\n'.join(command),
        execution_requirements = {"block-network": ""}
    )

    return [DefaultInfo(files = depset(direct=outputs),),
            OutputGroupInfo(headers = depset([files.out_includes_folder]),  # can we have list here?
                            libfile = depset([files.out_lib_file]),
                            pkg_configs = pkg_configs),
            ]

def join_flags_string(flags_dict):
    flags = ""
    for key in flags_dict.keys():
      if (len(flags_dict[key]) > 0):
        if (len(flags) > 0):
          flags += " "
        if (key != 'PKG_CONFIG_PATH'):
          flags += key + "=\"" + flags_dict[key] + "\""
    return flags

def init(value, default_value):
  if (value):
    return value
  return default_value

def define_files(ctx):
  lib_name = ctx.attr.lib_name
  lib_folder_name = init(ctx.attr.out_lib_folder, "lib")
  out_lib_file = ctx.actions.declare_file("/".join(
      [lib_name, lib_folder_name, init(ctx.attr.out_lib_name, lib_name + ".a")]))
  out_pkg_folder = None
  if ctx.attr.out_pkg_config_folder:
    out_pkg_folder = ctx.actions.declare_file("/".join([lib_name, lib_folder_name, "pkgconfig"]))

  deps = {}
  all_deps = []
  for dep in ctx.attr.deps.keys():
    dep_name = ctx.attr.deps[dep]
    deps_libs = []
    deps_headers = []
    deps_pkgs = []

    if dep[OutputGroupInfo] and hasattr(dep[OutputGroupInfo], "libfile"):
      provider = dep[OutputGroupInfo]
      # or do we want to be able to produce several files?
      libfiles = provider.libfile.to_list()
      if len(libfiles) != 1:
        fail("Expected exactly one libfile")
      deps_libs += libfiles or []
      deps_headers += provider.headers.to_list() or []
      deps_pkgs += provider.pkg_configs.to_list() or []
    else:
      libfiles = dep.files.to_list()
      if len(libfiles) != 1:
        fail("Expected exactly one libfile: " + str(libfiles) + ", dep: " + dep_name)
      deps_libs = libfiles or []
      deps_headers = dep.cc.transitive_headers.to_list() or []
    deps[dep_name] = struct(
        deps_libs = deps_libs,
        deps_headers = deps_headers,
        deps_pkgs = deps_pkgs
    )
    all_deps += deps_libs + deps_headers + deps_pkgs

  return struct(
      wrapper = ctx.actions.declare_directory(lib_name),
      out_includes_folder = ctx.actions.declare_directory(
        lib_name + "/" + init(ctx.attr.out_include_folder, "include")),
      out_lib_folder = ctx.actions.declare_directory(lib_name + "/" + lib_folder_name),
      out_lib_file = out_lib_file,
      out_pkg_folder = out_pkg_folder,
      deps = deps,
      all_deps = all_deps
  )

def partition_key(flag):
    before, root, after = flag.partition("$root(")
    if (after):
      link, paren, end = after.partition(")")
      if link and paren:
        return before, link, end
    return None, None, None

def process_configure_flags(ctx, files):
    root_expr = "$root"
    processed_configure_flags = []
    for flag in ctx.attr.configure_flags:
      before, key, after = partition_key(flag)
      if key:
        processed_configure_flags += [before + "$tmplib/" + key + after]
      else:
        processed_configure_flags += [flag]
    return " ".join(processed_configure_flags)

def deps_into_flags(list, prefix, separator):
  return separator.join([prefix + elem.path for elem in list])

def strings_into_flags(list, separator):
  return separator.join([elem for elem in list])

def define_parameters(ctx, files):
  cpp_fragment = ctx.fragments.cpp
  compiler_options = [] # todo ?? cpp_fragment.compiler_options(ctx.features)

  return struct(
      flags = {
        "CFLAGS": strings_into_flags(compiler_options + cpp_fragment.c_options, " "),
        "CXXFLAGS": strings_into_flags(compiler_options + cpp_fragment.cxx_options(ctx.features), " "),
        "LDFLAGS": " ".join(["-L$tmplib/{}/lib".format(key) for key in files.deps.keys()]),
        "CPPFLAGS": " ".join(["-I$tmplib/{}/include".format(key) for key in files.deps.keys()]),
        "PKG_CONFIG_PATH": ":".join(["$tmplib/{}/lib/pkgconfig".format(key) for key in files.deps.keys()]),
        },
      processed_configure_params = process_configure_flags(ctx, files)
)

cc_configure_make = rule(
    attrs = {
        "lib_name": attr.string(mandatory = True),
        "configure_flags": attr.string_list(),
        "srcs": attr.label(mandatory = True),

        "out_lib_folder": attr.string(mandatory = False),
        "out_lib_name": attr.string(mandatory = False),
        "out_include_folder": attr.string(mandatory = False),
        "out_pkg_config_folder": attr.bool(mandatory = True),
        "deps": attr.label_keyed_string_dict(mandatory = False),

        "trace": attr.bool(mandatory = False)
    },
    fragments = ["cpp"],
    output_to_genfiles = True,
    implementation = _cc_configure_make
)

def generated_name(name):
    return '_{}_cc_configure_make'.format(name)

def cc_configure_make_binary_tmp_macros(
    name,
    configure_flags,
    srcs,
    lib_name = None,
    out_lib_folder = None,
    out_lib_name = None,
    out_include_folder = None,
    out_pkg_config_folder = True,
    deps = None,
    trace = True
):
    name_cmr = generated_name(name)
    processed_deps = {}
    if deps:
      for target in deps:
        gen_name = generated_name(target)
        if gen_name in native.existing_rules():
          processed_deps[gen_name] = target
        else:
          processed_deps[target] = target

    cc_configure_make(
        lib_name = init(lib_name, name),
        name = name_cmr,
        configure_flags = configure_flags,
        srcs = srcs,
        out_lib_folder = out_lib_folder,
        out_lib_name = out_lib_name,
        out_include_folder = out_include_folder,
        out_pkg_config_folder = out_pkg_config_folder,
        deps = processed_deps,
        trace = trace
    )

    native.filegroup(
      name = name,
      srcs = [name_cmr],
      output_group = "libfile",
    )

def cc_configure_make_tmp_macros(
    name,
    configure_flags,
    srcs,
    lib_name = None,
    out_lib_folder = None,
    out_lib_name = None,
    out_include_folder = None,
    out_pkg_config_folder = True,
    deps = None,
    trace = True
):
    name_cmr = generated_name(name)
    processed_deps = {}
    if deps:
      for target in deps:
        gen_name = generated_name(target)
        if gen_name in native.existing_rules():
          processed_deps[gen_name] = target
        else:
          processed_deps[target] = target

    cc_configure_make(
        lib_name = init(lib_name, name),
        name = name_cmr,
        configure_flags = configure_flags,
        srcs = srcs,
        out_lib_folder = out_lib_folder,
        out_lib_name = out_lib_name,
        out_include_folder = out_include_folder,
        out_pkg_config_folder = out_pkg_config_folder,
        deps = processed_deps,
        trace = trace
    )

    name_libfile_fg = '_{}_libfile_fg'.format(name)
    native.filegroup(
        name = name_libfile_fg,
        srcs = [name_cmr],
        output_group = "libfile",
    )

    name_libfile_import = '_{}_libfile_import'.format(name)
    native.cc_import(
        name = name_libfile_import,
        static_library = name_libfile_fg,
    )

    name_headers_fg = '_{}_headers_fg'.format(name)
    native.filegroup(
        name = name_headers_fg,
        srcs = [name_cmr],
        output_group = "headers",
    )

    native.cc_library(
        name = name,
        hdrs = [name_headers_fg],
        includes = [name + "/include"],
        deps = [name_libfile_import],
    )
