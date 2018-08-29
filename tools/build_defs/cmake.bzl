""" Defines the rule for building external library with CMake
"""

load(
    "//tools/build_defs:framework.bzl",
    "CC_EXTERNAL_RULE_ATTRIBUTES",
    "cc_external_rule_impl",
    "create_attrs",
)
load(
    "//tools/build_defs:detect_root.bzl",
    "detect_root",
)
load(
    "//tools/build_defs:cc_toolchain_util.bzl",
    "absolutize_path_in_str",
    "get_flags_info",
    "get_tools_info",
)
load("@foreign_cc_platform_utils//:cmake_globals.bzl", "CMAKE_COMMAND", "CMAKE_DEPS")

def _cmake_external(ctx):
    options = " ".join(ctx.attr.cmake_options)
    root = detect_root(ctx.attr.lib_source)

    tools = get_tools_info(ctx)
    flags = get_flags_info(ctx)
    no_toolchain_file = ctx.attr.cache_entries.get("CMAKE_TOOLCHAIN_FILE") or not ctx.attr.generate_crosstool_file
    params = None
    if no_toolchain_file:
        params = _create_cache_entries_env_vars(ctx, tools, flags)
    else:
        params = _create_crosstool_file_text(ctx, tools, flags)

    install_prefix = _get_install_prefix(ctx)
    configure_script = "\n".join([] + params.commands + [" ".join([
        " ".join([key + "=\"" + params.env[key] + "\"" for key in params.env]),
        " " + CMAKE_COMMAND,
        " ".join(["-D" + key + "=\"" + params.cache[key] + "\"" for key in params.cache]),
        "-DCMAKE_PREFIX_PATH=\"$EXT_BUILD_DEPS\"",
        "-DCMAKE_INSTALL_PREFIX=\"{}\"".format(install_prefix),
        " ".join(params.options + [options]),
        "$EXT_BUILD_ROOT/" + root,
    ])])
    copy_results = "copy_dir_contents_to_dir $TMPDIR/{} $INSTALLDIR".format(install_prefix)

    tools_deps = ctx.attr.tools_deps + [ctx.attr._cmake_dep]
    attrs = create_attrs(
        ctx.attr,
        configure_name = "CMake",
        configure_script = configure_script,
        postfix_script = copy_results + "\n" + ctx.attr.postfix_script,
        tools_deps = tools_deps,
    )

    return cc_external_rule_impl(ctx, attrs)

def _get_install_prefix(ctx):
    if ctx.attr.install_prefix:
        prefix = ctx.attr.install_prefix

        # If not in sandbox, or after the build, the value can be absolute.
        # So if the user passed the absolute value, do not touch it.
        if (prefix.startswith("/")):
            return prefix
        return prefix if prefix.startswith("./") else "./" + prefix
    if ctx.attr.lib_name:
        return "./" + ctx.attr.lib_name
    return "./" + ctx.attr.name

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

def _create_crosstool_file_text(ctx, tools, flags):
    dict = fill_crossfile_from_toolchain(ctx, tools, flags)
    print("ctx.attr.cache_entries: " + str(ctx.attr.cache_entries))
    cache_entries = _dict_copy(ctx.attr.cache_entries)
    print("cache_entries: " + str(cache_entries))
    env_vars = _dict_copy(ctx.attr.env_vars)
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

def _create_cache_entries_env_vars(ctx, tools, flags):
    dict = fill_crossfile_from_toolchain(ctx, tools, flags)
    merged_env_entries = _merge_toolchain_and_user_values(dict, ctx.attr.env_vars, _CMAKE_ENV_VARS_FOR_CROSSTOOL)
    merged_cache_entries = _merge_toolchain_and_user_values(dict, ctx.attr.cache_entries, _CMAKE_CACHE_ENTRIES_CROSSTOOL)
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

def fill_crossfile_from_toolchain(ctx, tools, flags):
    dict = {
        "CMAKE_SYSTEM_NAME": "Linux",
    }

    _sysroot = _find_in_cc_or_cxx(flags, "sysroot")
    if _sysroot:
        dict["CMAKE_SYSROOT"] = _absolutize(ctx, _sysroot)

    _ext_toolchain_cc = _find_flag_value(flags.cc, "gcc_toolchain")
    if _ext_toolchain_cc:
        dict["CMAKE_C_COMPILER_EXTERNAL_TOOLCHAIN"] = _absolutize(ctx, _ext_toolchain_cc)

    _ext_toolchain_cxx = _find_flag_value(flags.cxx, "gcc_toolchain")
    if _ext_toolchain_cxx:
        dict["CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN"] = _absolutize(ctx, _ext_toolchain_cxx)

    if tools.cc:
        dict["CMAKE_C_COMPILER"] = _absolutize(ctx, tools.cc)
    if tools.cxx:
        dict["CMAKE_CXX_COMPILER"] = _absolutize(ctx, tools.cxx)

    if tools.cxx_linker_static:
        dict["CMAKE_AR"] = _absolutize(ctx, tools.cxx_linker_static)

    if tools.cxx_linker_executable:
        normalized_path = _absolutize(ctx, tools.cxx_linker_executable)
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
        dict["CMAKE_C_FLAGS_INIT"] = _join_flags_list(ctx, flags.cc)
    if flags.cxx:
        dict["CMAKE_CXX_FLAGS_INIT"] = _join_flags_list(ctx, flags.cxx)
    if flags.assemble:
        dict["CMAKE_ASM_FLAGS_INIT"] = _join_flags_list(ctx, flags.assemble)

    # todo this options are needed, but cause a bug because the flags are put in wrong order => keep this line
    #    if flags.cxx_linker_static:
    #        lines += [_set_list(ctx, "CMAKE_STATIC_LINKER_FLAGS_INIT", flags.cxx_linker_static)]
    if flags.cxx_linker_shared:
        dict["CMAKE_SHARED_LINKER_FLAGS_INIT"] = _join_flags_list(ctx, flags.cxx_linker_shared)
    if flags.cxx_linker_executable:
        dict["CMAKE_EXE_LINKER_FLAGS_INIT"] = _join_flags_list(ctx, flags.cxx_linker_executable)

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

def _join_cache_options(ctx, toolchain_entries, user_entries):
    cache_entries = dict(toolchain_entries)

    for key in user_entries:
        existing = []
        if cache_entries.get(key, None):
            existing = cache_entries[key]
        cache_entries[key] = existing + [user_entries[key]]

    return [_option(ctx, key, cache_entries[key]) for key in cache_entries]

def _env_var(ctx, cmake_option, flags):
    return "{}=\"{}\"".format(cmake_option, _join_flags_list(ctx, flags))

def _option(ctx, cmake_option, flags):
    return "-D{}=\"{}\"".format(cmake_option, _join_flags_list(ctx, flags))

def _absolutize(ctx, flag):
    return absolutize_path_in_str(ctx, flag, "$EXT_BUILD_ROOT/")

def _join_flags_list(ctx, flags):
    return " ".join([_absolutize(ctx, flag) for flag in flags])

def _attrs():
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
    attrs.update({
        # Relative install prefix to be passed to CMake in -DCMAKE_INSTALL_PREFIX
        "install_prefix": attr.string(mandatory = False),
        # CMake cache entries to initialize (they will be passed with -Dkey=value)
        # Values, defined by the toolchain, will be joined with the values, passed here.
        # (Toolchain values come first)
        "cache_entries": attr.string_dict(mandatory = False, default = {}),
        # CMake environment variable values to join with toolchain-defined.
        # For example, additional CXXFLAGS.
        "env_vars": attr.string_dict(mandatory = False, default = {}),
        # Other CMake options
        "cmake_options": attr.string_list(mandatory = False, default = []),
        # When True, CMake crosstool file will be generated from the toolchain values,
        # provided cache-entries and env_vars (some values will still be passed as -Dkey=value
        # and environment variables).
        # If CMAKE_TOOLCHAIN_FILE cache entry is passed, specified crosstool file will be used
        # When using this option, it makes sense to specify CMAKE_SYSTEM_NAME in the
        # cache_entries - the rule makes only a poor guess about the target system,
        # it is better to specify it manually.
        "generate_crosstool_file": attr.bool(mandatory = False, default = True),
        "_cmake_dep": attr.label(
            default = "@foreign_cc_platform_utils//:cmake",
            cfg = "target",
            allow_files = True,
        ),
    })
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
