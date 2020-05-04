""" Unit tests for CMake script creation """

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//tools/build_defs:cmake_script.bzl", "create_cmake_script", "export_for_test")
load("//tools/build_defs:cc_toolchain_util.bzl", "CxxFlagsInfo", "CxxToolsInfo")

def _absolutize_test(ctx):
    env = unittest.begin(ctx)

    cases = {
        "abs/a12": "abs/a12",
        "/abs/a12": "/abs/a12",
        "external/cmake/aaa": "$EXT_BUILD_ROOT/external/cmake/aaa",
        "-Lexternal/cmake/aaa": "-L$EXT_BUILD_ROOT/external/cmake/aaa",
        "ws/cmake/aaa": "$EXT_BUILD_ROOT/ws/cmake/aaa",
        "name=ws/cmake/aaa": "name=$EXT_BUILD_ROOT/ws/cmake/aaa",
    }

    for case in cases:
        res = export_for_test.absolutize("ws", case)
        asserts.equals(env, cases[case], res)

    return unittest.end(env)

def _tail_extraction_test(ctx):
    env = unittest.begin(ctx)

    res = export_for_test.tail_if_starts_with("absolutely", "abs")
    asserts.equals(env, "olutely", res)

    res = export_for_test.tail_if_starts_with("--option=value", "-option")
    asserts.equals(env, None, res)

    res = export_for_test.tail_if_starts_with("--option=value", "--option")
    asserts.equals(env, "=value", res)

    return unittest.end(env)

def _find_flag_value_test(ctx):
    env = unittest.begin(ctx)

    found_cases = [
        ["--gcc_toolchain=/abc/def"],
        ["--gcc_toolchain =/abc/def"],
        ["--gcc_toolchain= /abc/def"],
        ["--gcc_toolchain = /abc/def"],
        ["  --gcc_toolchain = /abc/def"],
        ["--gcc_toolchain", "=/abc/def"],
        ["--gcc_toolchain", "/abc/def"],
        ["-gcc_toolchain", "/abc/def"],
        ["-gcc_toolchain=/abc/def"],
        ["-gcc_toolchain = /abc/def"],
        ["--gcc_toolchain /abc/def"],
    ]

    for case in found_cases:
        res = export_for_test.find_flag_value(case, "gcc_toolchain")
        asserts.equals(env, "/abc/def", res, msg = "Not equals: " + str(case))

    not_found_cases = [
        ["--gcc_toolchainn=/abc/def"],
        ["--gcc_toolchain abc/def"],
    ]
    for case in not_found_cases:
        res = export_for_test.find_flag_value(case, "gcc_toolchain")
        asserts.false(env, "/abc/def" == res, msg = "Equals: " + str(case))

    return unittest.end(env)

def _fill_crossfile_from_toolchain_test(ctx):
    env = unittest.begin(ctx)

    tools = CxxToolsInfo(
        cc = "/some-cc-value",
        cxx = "external/cxx-value",
        cxx_linker_static = "/cxx_linker_static",
        cxx_linker_executable = "ws/cxx_linker_executable",
    )
    flags = CxxFlagsInfo(
        cc = ["-cc-flag", "-gcc_toolchain", "cc-toolchain"],
        cxx = ["--quoted=\"abc def\"", "--sysroot=/abc/sysroot", "--gcc_toolchain", "cxx-toolchain"],
        cxx_linker_shared = ["shared1", "shared2"],
        cxx_linker_static = ["static"],
        cxx_linker_executable = ["executable"],
        assemble = ["assemble"],
    )

    res = export_for_test.fill_crossfile_from_toolchain("ws", "linux", tools, flags)

    system = res.pop("CMAKE_SYSTEM_NAME")
    asserts.true(env, system != None)

    expected = {
        "CMAKE_SYSROOT": "/abc/sysroot",
        "CMAKE_C_COMPILER_EXTERNAL_TOOLCHAIN": "cc-toolchain",
        "CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN": "cxx-toolchain",
        "CMAKE_C_COMPILER": "/some-cc-value",
        "CMAKE_CXX_COMPILER": "$EXT_BUILD_ROOT/external/cxx-value",
        "CMAKE_AR": "/cxx_linker_static",
        "CMAKE_CXX_LINK_EXECUTABLE": "$EXT_BUILD_ROOT/ws/cxx_linker_executable <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>",
        "CMAKE_C_FLAGS_INIT": "-cc-flag -gcc_toolchain cc-toolchain",
        "CMAKE_CXX_FLAGS_INIT": "--quoted=\\\"abc def\\\" --sysroot=/abc/sysroot --gcc_toolchain cxx-toolchain",
        "CMAKE_ASM_FLAGS_INIT": "assemble",
        "CMAKE_SHARED_LINKER_FLAGS_INIT": "shared1 shared2",
        "CMAKE_EXE_LINKER_FLAGS_INIT": "executable",
    }

    for key in expected:
        asserts.equals(env, expected[key], res[key])

    return unittest.end(env)

def _move_dict_values_test(ctx):
    env = unittest.begin(ctx)

    target = {
        "CMAKE_C_COMPILER": "some-cc-value",
        "CMAKE_CXX_COMPILER": "$EXT_BUILD_ROOT/external/cxx-value",
        "CMAKE_C_FLAGS_INIT": "-cc-flag -gcc_toolchain cc-toolchain",
        "CMAKE_CXX_LINK_EXECUTABLE": "was",
    }
    source_env = {
        "CC": "sink-cc-value",
        "CXX": "sink-cxx-value",
        "CFLAGS": "--from-env",
        "CUSTOM": "YES",
    }
    source_cache = {
        "CMAKE_C_FLAGS": "--additional-flag",
        "CMAKE_ASM_FLAGS": "assemble",
        "CMAKE_CXX_LINK_EXECUTABLE": "became",
        "CUSTOM": "YES",
    }
    export_for_test.move_dict_values(
        target,
        source_env,
        export_for_test.CMAKE_ENV_VARS_FOR_CROSSTOOL,
    )
    export_for_test.move_dict_values(
        target,
        source_cache,
        export_for_test.CMAKE_CACHE_ENTRIES_CROSSTOOL,
    )

    expected_target = {
        "CMAKE_C_COMPILER": "sink-cc-value",
        "CMAKE_CXX_COMPILER": "sink-cxx-value",
        "CMAKE_C_FLAGS_INIT": "-cc-flag -gcc_toolchain cc-toolchain --from-env --additional-flag",
        "CMAKE_ASM_FLAGS_INIT": "assemble",
        "CMAKE_CXX_LINK_EXECUTABLE": "became",
    }
    for key in expected_target:
        asserts.equals(env, expected_target[key], target[key])

    asserts.equals(env, "YES", source_env["CUSTOM"])
    asserts.equals(env, "YES", source_cache["CUSTOM"])
    asserts.equals(env, 1, len(source_env))
    asserts.equals(env, 1, len(source_cache))

    return unittest.end(env)

def _reverse_descriptor_dict_test(ctx):
    env = unittest.begin(ctx)

    res = export_for_test.reverse_descriptor_dict(export_for_test.CMAKE_CACHE_ENTRIES_CROSSTOOL)
    expected = {
        "CMAKE_SYSTEM_NAME": struct(value = "CMAKE_SYSTEM_NAME", replace = True),
        "CMAKE_AR": struct(value = "CMAKE_AR", replace = True),
        "CMAKE_CXX_LINK_EXECUTABLE": struct(value = "CMAKE_CXX_LINK_EXECUTABLE", replace = True),
        "CMAKE_C_FLAGS_INIT": struct(value = "CMAKE_C_FLAGS", replace = False),
        "CMAKE_CXX_FLAGS_INIT": struct(value = "CMAKE_CXX_FLAGS", replace = False),
        "CMAKE_ASM_FLAGS_INIT": struct(value = "CMAKE_ASM_FLAGS", replace = False),
        "CMAKE_STATIC_LINKER_FLAGS_INIT": struct(
            value = "CMAKE_STATIC_LINKER_FLAGS",
            replace = False,
        ),
        "CMAKE_SHARED_LINKER_FLAGS_INIT": struct(
            value = "CMAKE_SHARED_LINKER_FLAGS",
            replace = False,
        ),
        "CMAKE_EXE_LINKER_FLAGS_INIT": struct(value = "CMAKE_EXE_LINKER_FLAGS", replace = False),
    }

    for key in expected:
        asserts.equals(env, expected[key], res[key])

    return unittest.end(env)

def _merge_toolchain_and_user_values_test(ctx):
    env = unittest.begin(ctx)

    target = {
        "CMAKE_C_COMPILER": "some-cc-value",
        "CMAKE_CXX_COMPILER": "$EXT_BUILD_ROOT/external/cxx-value",
        "CMAKE_C_FLAGS_INIT": "-cc-flag -gcc_toolchain cc-toolchain",
        "CMAKE_CXX_FLAGS_INIT": "-ccx-flag",
        "CMAKE_CXX_LINK_EXECUTABLE": "was",
    }
    source_cache = {
        "CMAKE_C_FLAGS": "--additional-flag",
        "CMAKE_ASM_FLAGS": "assemble",
        "CMAKE_CXX_LINK_EXECUTABLE": "became",
        "CUSTOM": "YES",
    }

    res = export_for_test.merge_toolchain_and_user_values(
        target,
        source_cache,
        export_for_test.CMAKE_CACHE_ENTRIES_CROSSTOOL,
    )

    expected_target = {
        "CMAKE_C_FLAGS": "-cc-flag -gcc_toolchain cc-toolchain --additional-flag",
        "CMAKE_CXX_FLAGS": "-ccx-flag",
        "CMAKE_ASM_FLAGS": "assemble",
        "CMAKE_CXX_LINK_EXECUTABLE": "became",
        "CUSTOM": "YES",
    }

    for key in expected_target:
        asserts.equals(env, expected_target[key], res[key])

    return unittest.end(env)

def _merge_flag_values_no_toolchain_file_test(ctx):
    env = unittest.begin(ctx)

    tools = CxxToolsInfo(
        cc = "/usr/bin/gcc",
        cxx = "/usr/bin/gcc",
        cxx_linker_static = "/usr/bin/ar",
        cxx_linker_executable = "/usr/bin/gcc",
    )
    flags = CxxFlagsInfo(
        cc = [],
        cxx = ["foo=\"bar\""],
        cxx_linker_shared = [],
        cxx_linker_static = [],
        cxx_linker_executable = [],
        assemble = [],
    )
    user_env = {}
    user_cache = {
        "CMAKE_CXX_FLAGS": "-Fbat",
        "CMAKE_BUILD_TYPE": "RelWithDebInfo",
    }

    script = create_cmake_script(
        "ws",
        "linux",
        "cmake",
        tools,
        flags,
        "test_rule",
        "external/test_rule",
        True,
        user_cache,
        user_env,
        [],
    )
    expected = """CC=\"/usr/bin/gcc\" CXX=\"/usr/bin/gcc\" CXXFLAGS=\"foo=\\\"bar\\\" -Fbat" cmake -DCMAKE_AR=\"/usr/bin/ar\" -DCMAKE_BUILD_TYPE="RelWithDebInfo" -DCMAKE_PREFIX_PATH=\"$EXT_BUILD_DEPS\" -DCMAKE_INSTALL_PREFIX=\"test_rule\" -DCMAKE_RANLIB=\"\"  $EXT_BUILD_ROOT/external/test_rule"""
    asserts.equals(env, expected, script)

    return unittest.end(env)

def _create_min_cmake_script_no_toolchain_file_test(ctx):
    env = unittest.begin(ctx)

    tools = CxxToolsInfo(
        cc = "/usr/bin/gcc",
        cxx = "/usr/bin/gcc",
        cxx_linker_static = "/usr/bin/ar",
        cxx_linker_executable = "/usr/bin/gcc",
    )
    flags = CxxFlagsInfo(
        cc = ["-U_FORTIFY_SOURCE", "-fstack-protector", "-Wall"],
        cxx = ["-U_FORTIFY_SOURCE", "-fstack-protector", "-Wall"],
        cxx_linker_shared = ["-shared", "-fuse-ld=gold"],
        cxx_linker_static = ["static"],
        cxx_linker_executable = ["-fuse-ld=gold", "-Wl", "-no-as-needed"],
        assemble = ["-U_FORTIFY_SOURCE", "-fstack-protector", "-Wall"],
    )
    user_env = {}
    user_cache = {
        "NOFORTRAN": "on",
        "CMAKE_PREFIX_PATH": "/abc/def",
    }

    script = create_cmake_script(
        "ws",
        "linux",
        "cmake",
        tools,
        flags,
        "test_rule",
        "external/test_rule",
        True,
        user_cache,
        user_env,
        ["-GNinja"],
    )
    expected = "CC=\"/usr/bin/gcc\" CXX=\"/usr/bin/gcc\" CFLAGS=\"-U_FORTIFY_SOURCE -fstack-protector -Wall\" CXXFLAGS=\"-U_FORTIFY_SOURCE -fstack-protector -Wall\" ASMFLAGS=\"-U_FORTIFY_SOURCE -fstack-protector -Wall\" cmake -DCMAKE_AR=\"/usr/bin/ar\" -DCMAKE_SHARED_LINKER_FLAGS=\"-shared -fuse-ld=gold\" -DCMAKE_EXE_LINKER_FLAGS=\"-fuse-ld=gold -Wl -no-as-needed\" -DNOFORTRAN=\"on\" -DCMAKE_PREFIX_PATH=\"$EXT_BUILD_DEPS;/abc/def\" -DCMAKE_INSTALL_PREFIX=\"test_rule\" -DCMAKE_BUILD_TYPE=\"Debug\" -DCMAKE_RANLIB=\"\" -GNinja $EXT_BUILD_ROOT/external/test_rule"
    asserts.equals(env, expected, script)

    return unittest.end(env)

def _create_min_cmake_script_wipe_toolchain_test(ctx):
    env = unittest.begin(ctx)

    tools = CxxToolsInfo(
        cc = "/usr/bin/gcc",
        cxx = "/usr/bin/gcc",
        cxx_linker_static = "/usr/bin/ar",
        cxx_linker_executable = "/usr/bin/gcc",
    )
    flags = CxxFlagsInfo(
        cc = ["-U_FORTIFY_SOURCE", "-fstack-protector", "-Wall"],
        cxx = ["-U_FORTIFY_SOURCE", "-fstack-protector", "-Wall"],
        cxx_linker_shared = ["-shared", "-fuse-ld=gold"],
        cxx_linker_static = ["static"],
        cxx_linker_executable = ["-fuse-ld=gold", "-Wl", "-no-as-needed"],
        assemble = ["-U_FORTIFY_SOURCE", "-fstack-protector", "-Wall"],
    )
    user_env = {}
    user_cache = {
        "CMAKE_PREFIX_PATH": "/abc/def",
        # These two flags/CMake cache entries must be wiped,
        # but the second is not present in toolchain flags.
        "CMAKE_SHARED_LINKER_FLAGS": "",
        "WIPE_ME_IF_PRESENT": "",
    }

    script = create_cmake_script(
        "ws",
        "linux",
        "cmake",
        tools,
        flags,
        "test_rule",
        "external/test_rule",
        True,
        user_cache,
        user_env,
        ["-GNinja"],
    )
    expected = "CC=\"/usr/bin/gcc\" CXX=\"/usr/bin/gcc\" CFLAGS=\"-U_FORTIFY_SOURCE -fstack-protector -Wall\" CXXFLAGS=\"-U_FORTIFY_SOURCE -fstack-protector -Wall\" ASMFLAGS=\"-U_FORTIFY_SOURCE -fstack-protector -Wall\" cmake -DCMAKE_AR=\"/usr/bin/ar\" -DCMAKE_EXE_LINKER_FLAGS=\"-fuse-ld=gold -Wl -no-as-needed\" -DCMAKE_PREFIX_PATH=\"$EXT_BUILD_DEPS;/abc/def\" -DCMAKE_INSTALL_PREFIX=\"test_rule\" -DCMAKE_BUILD_TYPE=\"Debug\" -DCMAKE_RANLIB=\"\" -GNinja $EXT_BUILD_ROOT/external/test_rule"
    asserts.equals(env, expected, script)

    return unittest.end(env)

def _create_min_cmake_script_toolchain_file_test(ctx):
    env = unittest.begin(ctx)

    tools = CxxToolsInfo(
        cc = "/usr/bin/gcc",
        cxx = "/usr/bin/gcc",
        cxx_linker_static = "/usr/bin/ar",
        cxx_linker_executable = "/usr/bin/gcc",
    )
    flags = CxxFlagsInfo(
        cc = ["-U_FORTIFY_SOURCE", "-fstack-protector", "-Wall"],
        cxx = ["-U_FORTIFY_SOURCE", "-fstack-protector", "-Wall"],
        cxx_linker_shared = ["-shared", "-fuse-ld=gold"],
        cxx_linker_static = ["static"],
        cxx_linker_executable = ["-fuse-ld=gold", "-Wl", "-no-as-needed"],
        assemble = ["-U_FORTIFY_SOURCE", "-fstack-protector", "-Wall"],
    )
    user_env = {}
    user_cache = {
        "NOFORTRAN": "on",
    }

    script = create_cmake_script(
        "ws",
        "linux",
        "cmake",
        tools,
        flags,
        "test_rule",
        "external/test_rule",
        False,
        user_cache,
        user_env,
        ["-GNinja"],
    )
    expected = """cat > crosstool_bazel.cmake <<EOF
set(CMAKE_SYSTEM_NAME "Linux")
set(CMAKE_C_COMPILER "/usr/bin/gcc")
set(CMAKE_CXX_COMPILER "/usr/bin/gcc")
set(CMAKE_AR "/usr/bin/ar" CACHE FILEPATH "Archiver")
set(CMAKE_C_FLAGS_INIT "-U_FORTIFY_SOURCE -fstack-protector -Wall")
set(CMAKE_CXX_FLAGS_INIT "-U_FORTIFY_SOURCE -fstack-protector -Wall")
set(CMAKE_ASM_FLAGS_INIT "-U_FORTIFY_SOURCE -fstack-protector -Wall")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-shared -fuse-ld=gold")
set(CMAKE_EXE_LINKER_FLAGS_INIT "-fuse-ld=gold -Wl -no-as-needed")
EOF

 cmake -DNOFORTRAN="on" -DCMAKE_TOOLCHAIN_FILE="crosstool_bazel.cmake" -DCMAKE_PREFIX_PATH="$EXT_BUILD_DEPS" -DCMAKE_INSTALL_PREFIX="test_rule" -DCMAKE_BUILD_TYPE=\"Debug\" -DCMAKE_RANLIB=\"\" -GNinja $EXT_BUILD_ROOT/external/test_rule"""
    asserts.equals(env, expected.splitlines(), script.splitlines())

    return unittest.end(env)

def _create_cmake_script_no_toolchain_file_test(ctx):
    env = unittest.begin(ctx)

    tools = CxxToolsInfo(
        cc = "/some-cc-value",
        cxx = "external/cxx-value",
        cxx_linker_static = "/cxx_linker_static",
        cxx_linker_executable = "ws/cxx_linker_executable",
    )
    flags = CxxFlagsInfo(
        cc = ["-cc-flag", "-gcc_toolchain", "cc-toolchain"],
        cxx = [
            "--quoted=\"abc def\"",
            "--sysroot=/abc/sysroot",
            "--gcc_toolchain",
            "cxx-toolchain",
        ],
        cxx_linker_shared = ["shared1", "shared2"],
        cxx_linker_static = ["static"],
        cxx_linker_executable = ["executable"],
        assemble = ["assemble"],
    )
    user_env = {
        "CC": "sink-cc-value",
        "CXX": "sink-cxx-value",
        "CFLAGS": "--from-env",
        "CUSTOM_ENV": "YES",
    }
    user_cache = {
        "CMAKE_C_FLAGS": "--additional-flag",
        "CMAKE_ASM_FLAGS": "assemble-user",
        "CMAKE_CXX_LINK_EXECUTABLE": "became",
        "CUSTOM_CACHE": "YES",
        "CMAKE_BUILD_TYPE": "user_type",
    }

    script = create_cmake_script(
        "ws",
        "linux",
        "cmake",
        tools,
        flags,
        "test_rule",
        "external/test_rule",
        True,
        user_cache,
        user_env,
        ["-GNinja"],
    )
    expected = "CC=\"sink-cc-value\" CXX=\"sink-cxx-value\" CFLAGS=\"-cc-flag -gcc_toolchain cc-toolchain --from-env --additional-flag\" CXXFLAGS=\"--quoted=\\\"abc def\\\" --sysroot=/abc/sysroot --gcc_toolchain cxx-toolchain\" ASMFLAGS=\"assemble assemble-user\" CUSTOM_ENV=\"YES\" cmake -DCMAKE_AR=\"/cxx_linker_static\" -DCMAKE_CXX_LINK_EXECUTABLE=\"became\" -DCMAKE_SHARED_LINKER_FLAGS=\"shared1 shared2\" -DCMAKE_EXE_LINKER_FLAGS=\"executable\" -DCUSTOM_CACHE=\"YES\" -DCMAKE_BUILD_TYPE=\"user_type\" -DCMAKE_PREFIX_PATH=\"$EXT_BUILD_DEPS\" -DCMAKE_INSTALL_PREFIX=\"test_rule\" -DCMAKE_RANLIB=\"\" -GNinja $EXT_BUILD_ROOT/external/test_rule"
    asserts.equals(env, expected, script)

    return unittest.end(env)

def _create_cmake_script_toolchain_file_test(ctx):
    env = unittest.begin(ctx)

    tools = CxxToolsInfo(
        cc = "some-cc-value",
        cxx = "external/cxx-value",
        cxx_linker_static = "/cxx_linker_static",
        cxx_linker_executable = "ws/cxx_linker_executable",
    )
    flags = CxxFlagsInfo(
        cc = ["-cc-flag", "-gcc_toolchain", "cc-toolchain"],
        cxx = [
            "--quoted=\"abc def\"",
            "--sysroot=/abc/sysroot",
            "--gcc_toolchain",
            "cxx-toolchain",
        ],
        cxx_linker_shared = ["shared1", "shared2"],
        cxx_linker_static = ["static"],
        cxx_linker_executable = ["executable"],
        assemble = ["assemble"],
    )
    user_env = {
        "CC": "sink-cc-value",
        "CXX": "sink-cxx-value",
        "CFLAGS": "--from-env",
        "CUSTOM_ENV": "YES",
    }
    user_cache = {
        "CMAKE_C_FLAGS": "--additional-flag",
        "CMAKE_ASM_FLAGS": "assemble-user",
        "CMAKE_CXX_LINK_EXECUTABLE": "became",
        "CUSTOM_CACHE": "YES",
    }

    script = create_cmake_script(
        "ws",
        "osx",
        "cmake",
        tools,
        flags,
        "test_rule",
        "external/test_rule",
        False,
        user_cache,
        user_env,
        ["-GNinja"],
    )
    expected = """cat > crosstool_bazel.cmake <<EOF
set(CMAKE_SYSTEM_NAME "Apple")
set(CMAKE_SYSROOT "/abc/sysroot")
set(CMAKE_C_COMPILER_EXTERNAL_TOOLCHAIN "cc-toolchain")
set(CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN "cxx-toolchain")
set(CMAKE_C_COMPILER "sink-cc-value")
set(CMAKE_CXX_COMPILER "sink-cxx-value")
set(CMAKE_AR "/cxx_linker_static" CACHE FILEPATH "Archiver")
set(CMAKE_CXX_LINK_EXECUTABLE "became")
set(CMAKE_C_FLAGS_INIT "-cc-flag -gcc_toolchain cc-toolchain --from-env --additional-flag")
set(CMAKE_CXX_FLAGS_INIT "--quoted=\\\"abc def\\\" --sysroot=/abc/sysroot --gcc_toolchain cxx-toolchain")
set(CMAKE_ASM_FLAGS_INIT "assemble assemble-user")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "shared1 shared2")
set(CMAKE_EXE_LINKER_FLAGS_INIT "executable")
EOF

CUSTOM_ENV="YES" cmake -DCUSTOM_CACHE="YES" -DCMAKE_TOOLCHAIN_FILE="crosstool_bazel.cmake" -DCMAKE_PREFIX_PATH="$EXT_BUILD_DEPS" -DCMAKE_INSTALL_PREFIX="test_rule" -DCMAKE_BUILD_TYPE=\"Debug\" -DCMAKE_RANLIB=\"\" -GNinja $EXT_BUILD_ROOT/external/test_rule"""
    asserts.equals(env, expected.splitlines(), script.splitlines())

    return unittest.end(env)

absolutize_test = unittest.make(_absolutize_test)
tail_extraction_test = unittest.make(_tail_extraction_test)
find_flag_value_test = unittest.make(_find_flag_value_test)
fill_crossfile_from_toolchain_test = unittest.make(_fill_crossfile_from_toolchain_test)
move_dict_values_test = unittest.make(_move_dict_values_test)
reverse_descriptor_dict_test = unittest.make(_reverse_descriptor_dict_test)
merge_toolchain_and_user_values_test = unittest.make(_merge_toolchain_and_user_values_test)
create_min_cmake_script_no_toolchain_file_test = unittest.make(_create_min_cmake_script_no_toolchain_file_test)
create_min_cmake_script_toolchain_file_test = unittest.make(_create_min_cmake_script_toolchain_file_test)
create_cmake_script_no_toolchain_file_test = unittest.make(_create_cmake_script_no_toolchain_file_test)
create_cmake_script_toolchain_file_test = unittest.make(_create_cmake_script_toolchain_file_test)
merge_flag_values_no_toolchain_file_test = unittest.make(_merge_flag_values_no_toolchain_file_test)
create_min_cmake_script_wipe_toolchain_test = unittest.make(_create_min_cmake_script_wipe_toolchain_test)

def cmake_script_test_suite():
    unittest.suite(
        "cmake_script_test_suite",
        absolutize_test,
        tail_extraction_test,
        find_flag_value_test,
        fill_crossfile_from_toolchain_test,
        move_dict_values_test,
        reverse_descriptor_dict_test,
        merge_toolchain_and_user_values_test,
        create_min_cmake_script_no_toolchain_file_test,
        create_min_cmake_script_toolchain_file_test,
        create_cmake_script_no_toolchain_file_test,
        create_cmake_script_toolchain_file_test,
        merge_flag_values_no_toolchain_file_test,
        create_min_cmake_script_wipe_toolchain_test,
    )
