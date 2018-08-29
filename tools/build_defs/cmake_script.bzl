load("@foreign_cc_platform_utils//:cmake_globals.bzl", "CMAKE_COMMAND", "CMAKE_DEPS")
load(":cc_toolchain_util.bzl", "absolutize_path_in_str")

def create_cmake_script(workspace_name, tools, flags, install_prefix, root, no_toolchain_file, user_cache, user_env, options):
    params = None
    if no_toolchain_file:
        params = _create_cache_entries_env_vars(workspace_name, tools, flags, user_cache, user_env)
    else:
        params = _create_crosstool_file_text(workspace_name, tools, flags, user_cache, user_env)

    # todo simplify
    return "\n".join([] + params.commands + [" ".join([
        " ".join([key + "=\"" + params.env[key] + "\"" for key in params.env]),
        " " + CMAKE_COMMAND,
        " ".join(["-D" + key + "=\"" + params.cache[key] + "\"" for key in params.cache]),
        "-DCMAKE_PREFIX_PATH=\"$EXT_BUILD_DEPS\"",
        "-DCMAKE_INSTALL_PREFIX=\"{}\"".format(install_prefix),
        " ".join(params.options + options),
        "$EXT_BUILD_ROOT/" + root,
    ])])

_CMAKE_ENV_VARS_FOR_CROSSTOOL = {
    "CC": struct(value = "CMAKE_C_COMPILER", replace = True),
    "CXX": struct(value = "CMAKE_CXX_COMPILER", replace = True),
    "CFLAGS": struct(value = "CMAKE_C_FLAGS_INIT", replace = False),
    "CXXFLAGS": struct(value = "CMAKE_CXX_FLAGS_INIT", replace = False),
    "ASMFLAGS": struct(value = "CMAKE_ASM_FLAGS_INIT", replace = False),
}

_CMAKE_CACHE_ENTRIES_CROSSTOOL = {
    "CMAKE_SYSTEM_NAME": struct(value = "CMAKE_SYSTEM_NAME", replace = True),
    "CMAKE_AR": struct(value = "CMAKE_AR", replace = True),
    "CMAKE_CXX_LINK_EXECUTABLE": struct(value = "CMAKE_CXX_LINK_EXECUTABLE", replace = True),
    "CMAKE_C_FLAGS": struct(value = "CMAKE_C_FLAGS_INIT", replace = False),
    "CMAKE_CXX_FLAGS": struct(value = "CMAKE_CXX_FLAGS_INIT", replace = False),
    "CMAKE_ASM_FLAGS": struct(value = "CMAKE_ASM_FLAGS_INIT", replace = False),
    "CMAKE_STATIC_LINKER_FLAGS": struct(value = "CMAKE_STATIC_LINKER_FLAGS_INIT", replace = False),
    "CMAKE_SHARED_LINKER_FLAGS": struct(value = "CMAKE_SHARED_LINKER_FLAGS_INIT", replace = False),
    "CMAKE_EXE_LINKER_FLAGS": struct(value = "CMAKE_EXE_LINKER_FLAGS_INIT", replace = False),
}

def _create_crosstool_file_text(workspace_name, tools, flags, user_cache, user_env):
    dict = fill_crossfile_from_toolchain(workspace_name, tools, flags)
    cache_entries = _dict_copy(user_cache)
    env_vars = _dict_copy(user_env)
    _merge_dict(dict, env_vars, _CMAKE_ENV_VARS_FOR_CROSSTOOL)
    _merge_dict(dict, cache_entries, _CMAKE_CACHE_ENTRIES_CROSSTOOL)

    lines = []
    for key in dict:
        if ("CMAKE_AR" == key):
            lines += ["set({} \"{}\" {})".format(key, dict[key], "CACHE FILEPATH \"Archiver\"")]
            continue
        lines += ["set({} \"{}\")".format(key, dict[key])]

    return struct(
        commands = ["cat > crosstool_bazel.cmake <<EOF\n" + "\n".join(lines) + "\nEOF\n"],
        options = ["-DCMAKE_TOOLCHAIN_FILE=crosstool_bazel.cmake"],
        env = env_vars,
        cache = cache_entries,
    )

def _dict_copy(d):
    out = {}
    if d:
        out.update(d)
    return out

def _create_cache_entries_env_vars(workspace_name, tools, flags, user_cache, user_env):
    dict = fill_crossfile_from_toolchain(workspace_name, tools, flags)
    dict.pop("CMAKE_SYSTEM_NAME")  # specify this only in a toolchain file
    merged_env_entries = _merge_toolchain_and_user_values(dict, user_env, _CMAKE_ENV_VARS_FOR_CROSSTOOL)
    merged_cache_entries = _merge_toolchain_and_user_values(dict, user_cache, _CMAKE_CACHE_ENTRIES_CROSSTOOL)
    return struct(
        commands = [],
        options = [],
        env = merged_env_entries,
        cache = merged_cache_entries,
    )

def _merge_toolchain_and_user_values(toolchain_dict, user_dict, descriptor_map):
    reverse = _reverse_descriptor_dict(descriptor_map)
    env_vars_toolchain = dict()

    keys = toolchain_dict.keys()
    for key in keys:
        env_var_key = reverse.get(key)
        if env_var_key:
            env_vars_toolchain[env_var_key.value] = toolchain_dict.pop(key)
    _merge_dict(env_vars_toolchain, user_dict, reverse)

    # anything left in user's env_entries does not correspond to anything defined by toolchain
    # => simple merge
    env_vars_toolchain.update(user_dict)
    return env_vars_toolchain

def _reverse_descriptor_dict(dict):
    out_dict = {}

    for key in dict:
        value = dict[key]
        out_dict[value.value] = struct(value = key, replace = value.replace)

    return out_dict

def _merge_dict(toolchain_dict, user_dict, KEYS_MAP):
    keys = user_dict.keys()
    for key in keys:
        existing = KEYS_MAP.get(key)
        if existing:
            value = user_dict.pop(key)
            if existing.replace or toolchain_dict.get(existing.value) == None:
                toolchain_dict[existing.value] = value
            else:
                toolchain_dict[existing.value] = _merge(toolchain_dict[key], value)

def _merge(str1, str2):
    return str1.strip("\"'") + " " + str2.strip("\"'")

def fill_crossfile_from_toolchain(workspace_name, tools, flags):
    dict = {
        "CMAKE_SYSTEM_NAME": "Linux",
    }

    _sysroot = _find_in_cc_or_cxx(flags, "sysroot")
    if _sysroot:
        dict["CMAKE_SYSROOT"] = _absolutize(workspace_name, _sysroot)

    _ext_toolchain_cc = _find_flag_value(flags.cc, "gcc_toolchain")
    if _ext_toolchain_cc:
        dict["CMAKE_C_COMPILER_EXTERNAL_TOOLCHAIN"] = _absolutize(workspace_name, _ext_toolchain_cc)

    _ext_toolchain_cxx = _find_flag_value(flags.cxx, "gcc_toolchain")
    if _ext_toolchain_cxx:
        dict["CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN"] = _absolutize(workspace_name, _ext_toolchain_cxx)

    if tools.cc:
        dict["CMAKE_C_COMPILER"] = _absolutize(workspace_name, tools.cc)
    if tools.cxx:
        dict["CMAKE_CXX_COMPILER"] = _absolutize(workspace_name, tools.cxx)

    if tools.cxx_linker_static:
        dict["CMAKE_AR"] = _absolutize(workspace_name, tools.cxx_linker_static)

    if tools.cxx_linker_executable:
        normalized_path = _absolutize(workspace_name, tools.cxx_linker_executable)
        dict["CMAKE_CXX_LINK_EXECUTABLE"] = " ".join([
            normalized_path,
            "<FLAGS>",
            "<CMAKE_CXX_LINK_FLAGS>",
            "<LINK_FLAGS>",
            "<OBJECTS>",
            "-o <TARGET>",
            "<LINK_LIBRARIES>",
        ])

    if flags.cc:
        dict["CMAKE_C_FLAGS_INIT"] = _join_flags_list(workspace_name, flags.cc)
    if flags.cxx:
        dict["CMAKE_CXX_FLAGS_INIT"] = _join_flags_list(workspace_name, flags.cxx)
    if flags.assemble:
        dict["CMAKE_ASM_FLAGS_INIT"] = _join_flags_list(workspace_name, flags.assemble)

    # todo this options are needed, but cause a bug because the flags are put in wrong order => keep this line
    #    if flags.cxx_linker_static:
    #        lines += [_set_list(ctx, "CMAKE_STATIC_LINKER_FLAGS_INIT", flags.cxx_linker_static)]
    if flags.cxx_linker_shared:
        dict["CMAKE_SHARED_LINKER_FLAGS_INIT"] = _join_flags_list(workspace_name, flags.cxx_linker_shared)
    if flags.cxx_linker_executable:
        dict["CMAKE_EXE_LINKER_FLAGS_INIT"] = _join_flags_list(workspace_name, flags.cxx_linker_executable)

    return dict

def _find_in_cc_or_cxx(flags, flag_name_no_dashes):
    _value = _find_flag_value(flags.cxx, flag_name_no_dashes)
    if _value:
        return _value
    return _find_flag_value(flags.cc, flag_name_no_dashes)

def _find_flag_value(list, flag_name_no_dashes):
    one_dash = "-" + flag_name_no_dashes
    two_dash = "--" + flag_name_no_dashes

    check_for_value = False
    for value in list:
        if check_for_value:
            return value.lstrip(" =")
        _tail = _tail_if_starts_with(value, one_dash)
        _tail = _tail_if_starts_with(value, two_dash) if not _tail else _tail
        if _tail and len(_tail) > 0:
            return _tail.lstrip(" =")
        if _tail:
            check_for_value = True

def _tail_if_starts_with(str, start):
    if (str.startswith(start)):
        return str[len(start):]
    return None

def _absolutize(workspace_name, text):
    return absolutize_path_in_str(workspace_name, "$EXT_BUILD_ROOT/", text)

def _join_flags_list(workspace_name, flags):
    return " ".join([_absolutize(workspace_name, flag) for flag in flags])
