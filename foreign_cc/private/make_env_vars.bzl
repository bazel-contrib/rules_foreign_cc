"""Helper methods to assemble make env variables from Bazel information."""

load(":flag_utils.bzl", "absolutize_path_for_build_root", _join_flags_list = "join_flags_list")
load(":framework.bzl", "get_foreign_cc_dep")

# buildifier: disable=function-docstring
def get_make_env_vars(
        workspace_name,
        tools,
        flags,
        user_vars,
        deps,
        inputs,
        is_msvc,
        make_commands):
    vars = _get_make_variables(workspace_name, tools, flags, user_vars, make_commands)
    deps_flags = _define_deps_flags(deps, inputs, is_msvc)

    # bazel has no standard way to retrieve this value from the toolchain, but
    # some toolchains provide it and some build systems (like openssl) require
    # it for non-racy parallel builds.
    if "RANLIB" in user_vars:
        vars["RANLIB"] = [user_vars["RANLIB"]]

    elif "RANLIB" not in vars.keys():
        # For cross-compilation.
        vars["RANLIB"] = [":"]

    if "LDFLAGS" in vars.keys():
        vars["LDFLAGS"] = vars["LDFLAGS"] + deps_flags.libs
    else:
        vars["LDFLAGS"] = deps_flags.libs

    # -I flags should be put into preprocessor flags, CPPFLAGS
    # https://www.gnu.org/software/autoconf/manual/autoconf-2.63/html_node/Preset-Output-Variables.html
    if "CPPFLAGS" in vars.keys():
        vars["CPPFLAGS"] = vars["CPPFLAGS"] + deps_flags.flags
    else:
        vars["CPPFLAGS"] = deps_flags.flags

    return " ".join(["{}=\"{}\""
        .format(key, _join_flags_list(workspace_name, vars[key])) for key in vars])

# buildifier: disable=function-docstring
def get_ldflags_make_vars(
        executable_ldflags_vars,
        shared_ldflags_vars,
        dynamic_module_ldflags_vars,
        workspace_name,
        flags,
        user_vars,
        deps,
        inputs,
        is_msvc):
    vars = _get_ldflags_vars(executable_ldflags_vars, shared_ldflags_vars, dynamic_module_ldflags_vars, flags, user_vars)

    deps_flags = _define_deps_flags(deps, inputs, is_msvc)
    for key in vars.keys():
        vars[key] = vars[key] + deps_flags.libs

    return " ".join(["{}=\"{}\""
        .format(key, _join_flags_list(workspace_name, vars[key])) for key in vars])

def _define_deps_flags(deps, inputs, is_msvc):
    # It is very important to keep the order for the linker => put them into list
    lib_dirs = []

    # msvc compiler uses -LIBPATH instead of -L
    lib_flag = "-LIBPATH:" if is_msvc else "-L"

    # Here go libraries built with Bazel
    gen_dirs_set = {}
    for lib in inputs.libs:
        dir_ = lib.dirname
        if not gen_dirs_set.get(dir_):
            gen_dirs_set[dir_] = 1
            lib_dirs.append(lib_flag + "$$EXT_BUILD_ROOT$$/" + dir_)

    include_dirs = _get_include_flags(deps, inputs, is_msvc)

    # For the external libraries, we need to refer to the places where
    # we copied the dependencies ($EXT_BUILD_DEPS/<lib_name>), because
    # we also want configure to find that same files with pkg-config
    # -config or other mechanics.
    # Since we need the names of include and lib directories under
    # the $EXT_BUILD_DEPS/<lib_name>, we ask the provider.
    gen_dirs_set = {}
    for dep in deps:
        external_deps = get_foreign_cc_dep(dep)
        if external_deps:
            for artifact in external_deps.artifacts.to_list():
                if not gen_dirs_set.get(artifact.gen_dir):
                    gen_dirs_set[artifact.gen_dir] = 1

                    dir_name = artifact.gen_dir.basename
                    lib_dirs.append(lib_flag + "$$EXT_BUILD_DEPS$$/{}/{}".format(dir_name, artifact.lib_dir_name))

    return struct(
        libs = lib_dirs,
        flags = include_dirs,
    )

def _get_include_flags(deps, inputs, is_msvc):
    # MSVC does not support GCC's -iquote/-isystem distinction. Keep its
    # existing include order and header-directory fallback unchanged.
    if is_msvc:
        return _get_msvc_include_flags(deps, inputs)

    # InputFiles.include_dirs deliberately combines categories for staging and
    # CMake. Keep that contract; recover compiler classes from the merged CcInfo.
    compilation = inputs.deps_compilation_info
    ordinary = compilation.includes.to_list()
    system = compilation.system_includes.to_list() + getattr(compilation, "external_includes", depset()).to_list()
    quote = compilation.quote_includes.to_list()
    foreign_roots = {}
    foreign_includes = []
    for dep in deps:
        external_deps = get_foreign_cc_dep(dep)
        if external_deps:
            for artifact in external_deps.artifacts.to_list():
                staged = "$$EXT_BUILD_DEPS$$/" + artifact.gen_dir.basename
                foreign_roots[artifact.gen_dir.path] = staged

                # framework._define_outputs publishes CcInfo's individual
                # headers beside copy_<lib>/<lib>, the complete install tree.
                published = artifact.gen_dir.dirname.rsplit("/", 1)[0] + "/" + artifact.gen_dir.basename
                foreign_roots[published] = staged
                foreign_includes.append((published + "/" + artifact.include_dir_name).rstrip("/"))

    classified = [_include_path(directory, foreign_roots) for directory in ordinary + system + quote]
    paths = []
    seen = {}

    # GCC searches quote, ordinary, then system directories, preserving order
    # within each class.
    for flag, directories in [
        ("-iquote", quote),
        ("-I", ordinary),
        ("-isystem", system),
    ]:
        for directory in directories:
            path = _include_path(directory, foreign_roots)
            key = (flag, path)
            if key not in seen:
                seen[key] = True
                paths.append(flag + path)

    # Retain the legacy fallback for genuinely unclassified headers, without
    # turning quote-only or system headers back into ordinary -I search roots.
    for directory in inputs.include_dirs + foreign_includes:
        path = _include_path(directory, foreign_roots)
        if path not in classified and ("-I", path) not in seen:
            seen[("-I", path)] = True
            paths.append("-I" + path)
    for header in inputs.headers:
        header_path = _include_path(header.path, foreign_roots)
        if not any([_under_include(header_path, directory) for directory in classified]):
            directory = _include_path(header.dirname, foreign_roots)
            if ("-I", directory) not in seen:
                seen[("-I", directory)] = True
                paths.append("-I" + directory)
    return paths

def _get_msvc_include_flags(deps, inputs):
    include_dirs = {}
    for directory in inputs.include_dirs:
        include_dirs[directory] = "-I$$EXT_BUILD_ROOT$$/" + directory
    for header in inputs.headers:
        if header.dirname not in include_dirs:
            include_dirs[header.dirname] = "-I$$EXT_BUILD_ROOT$$/" + header.dirname
    flags = include_dirs.values()
    seen = {}
    for dep in deps:
        external_deps = get_foreign_cc_dep(dep)
        if external_deps:
            for artifact in external_deps.artifacts.to_list():
                if artifact.gen_dir not in seen:
                    seen[artifact.gen_dir] = True
                    flags.append("-I$$EXT_BUILD_DEPS$$/{}/{}".format(artifact.gen_dir.basename, artifact.include_dir_name))
    return flags

def _under_include(path, directory):
    if directory in ["", "."]:
        return not path.startswith("/")
    return path == directory or path.startswith(directory.rstrip("/") + "/")

def _include_path(directory, foreign_roots):
    # Foreign outputs are staged under EXT_BUILD_DEPS. Preserve any additional
    # include subdirectories exported by their CcInfo as well as the root.
    best = ""
    for root in foreign_roots:
        if _under_include(directory, root) and len(root) > len(best):
            best = root
    if best:
        return foreign_roots[best] + directory[len(best):]
    return "$$EXT_BUILD_ROOT$$" if directory in ["", "."] else "$$EXT_BUILD_ROOT$$/" + directory

# See https://www.gnu.org/software/make/manual/html_node/Implicit-Variables.html
_MAKE_FLAGS = {
    "ARFLAGS": "cxx_linker_static",
    # AR_FLAGS is sometimes used
    "AR_FLAGS": "cxx_linker_static",
    "ASFLAGS": "assemble",
    "CFLAGS": "cc",
    "CXXFLAGS": "cxx",
    "LDFLAGS": "cxx_linker_executable",
    # missing: cxx_linker_shared
}

_MAKE_TOOLS = {
    "AR": "cxx_linker_static",
    "CC": "cc",
    "CXX": "cxx",
    "LD": "ld",
    # missing: cxx_linker_executable
}

def _get_make_variables(workspace_name, tools, flags, user_env_vars, make_commands):
    vars = _merge_env_vars(flags, _MAKE_FLAGS, user_env_vars)

    # Add user defined CPPFLAGS
    user_cpp_flags = [flag for flag in user_env_vars.get("CPPFLAGS", "").split(" ") if flag]
    if user_cpp_flags:
        vars["CPPFLAGS"] = user_cpp_flags

    tools_dict = {}
    for tool in _MAKE_TOOLS:
        tool_value = getattr(tools, _MAKE_TOOLS[tool])
        if tool_value:
            # Force absolutize of tool paths, which may relative to the exec root (e.g. hermetic toolchains built from source)
            tool_value_absolute = absolutize_path_for_build_root(workspace_name, tool_value, True)

            # There are 2 conditions where we need to wrap the tool path in double quotes:
            # 1. If the tool path contains whitespaces (e.g. C:\Program Files\...),
            #    MSYS2 requires that the path is wrapped in double quotes.
            # 2. If nmake is used, it requires the tool path to be wrapped in double quotes,
            #    otherwise nmake will output the command as a string instead of executing it.
            if " " in tool_value_absolute or _nmake_in_make_commands(make_commands):
                tool_value_absolute = "\\\"" + tool_value_absolute + "\\\""

            tools_dict[tool] = [tool_value_absolute]

    # Replace tools paths if user passed other values
    for user_var in user_env_vars:
        toolchain_val = tools_dict.get(user_var)
        if toolchain_val:
            tools_dict[user_var] = [user_env_vars[user_var]]

    vars.update(tools_dict)

    # Do not put in the other user-defined env variables at this point as they
    # have already been exported globally by the prelude.

    return vars

def _get_ldflags_vars(
        executable_ldflags_vars,
        shared_ldflags_vars,
        dynamic_module_ldflags_vars,
        flags,
        user_env_vars):
    executable_ldflags = {var: "cxx_linker_executable" for var in executable_ldflags_vars}
    shared_ldflags = {var: "cxx_linker_shared" for var in shared_ldflags_vars}
    dynamic_module_ldflags = {var: "cxx_linker_dynamic_module" for var in dynamic_module_ldflags_vars}

    linker_make_flags = {}
    for ldflags in [executable_ldflags, shared_ldflags, dynamic_module_ldflags]:
        linker_make_flags.update(ldflags)

    return _merge_env_vars(flags, linker_make_flags, user_env_vars)

def _merge_env_vars(flags, make_flags, user_env_vars):
    vars = {}

    for flag in make_flags:
        toolchain_flags = getattr(flags, make_flags[flag], [])
        user_flags = [
            user_flag
            for user_flag in user_env_vars.get(flag, "").split(" ")
            if user_flag
        ]
        if toolchain_flags or user_flags:
            vars[flag] = toolchain_flags + user_flags
    return vars

def _nmake_in_make_commands(make_commands):
    return make_commands and "nmake.exe" in make_commands[0]
