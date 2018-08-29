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

    unittest.end(env)

def _tail_extraction_test(ctx):
    env = unittest.begin(ctx)

    res = export_for_test.tail_if_starts_with("absolutely", "abs")
    asserts.equals(env, "olutely", res)

    res = export_for_test.tail_if_starts_with("--option=value", "-option")
    asserts.equals(env, None, res)

    res = export_for_test.tail_if_starts_with("--option=value", "--option")
    asserts.equals(env, "=value", res)

    unittest.end(env)

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

    unittest.end(env)

def _fill_crossfile_from_toolchain_test(ctx):
    env = unittest.begin(ctx)

    tools = CxxToolsInfo(
        cc = "some-cc-value",
        cxx = "external/cxx-value",
        cxx_linker_static = "cxx_linker_static",
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

    res = export_for_test.fill_crossfile_from_toolchain("ws", tools, flags)

    system = res.pop("CMAKE_SYSTEM_NAME")
    asserts.true(env, system != None)

    expected = {
        "CMAKE_SYSROOT": "/abc/sysroot",
        "CMAKE_C_COMPILER_EXTERNAL_TOOLCHAIN": "cc-toolchain",
        "CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN": "cxx-toolchain",
        "CMAKE_C_COMPILER": "some-cc-value",
        "CMAKE_CXX_COMPILER": "$EXT_BUILD_ROOT/external/cxx-value",
        "CMAKE_AR": "cxx_linker_static",
        "CMAKE_CXX_LINK_EXECUTABLE": "$EXT_BUILD_ROOT/ws/cxx_linker_executable <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>",
        "CMAKE_C_FLAGS_INIT": "-cc-flag -gcc_toolchain cc-toolchain",
        "CMAKE_CXX_FLAGS_INIT": "--quoted=\\\"abc def\\\" --sysroot=/abc/sysroot --gcc_toolchain cxx-toolchain",
        "CMAKE_ASM_FLAGS_INIT": "assemble",
        "CMAKE_SHARED_LINKER_FLAGS_INIT": "shared1 shared2",
        "CMAKE_EXE_LINKER_FLAGS_INIT": "executable",
    }

    for key in expected:
        asserts.equals(env, expected[key], res[key])

    unittest.end(env)

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
    export_for_test.move_dict_values(target, source_env, export_for_test.CMAKE_ENV_VARS_FOR_CROSSTOOL)
    export_for_test.move_dict_values(target, source_cache, export_for_test.CMAKE_CACHE_ENTRIES_CROSSTOOL)

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

    unittest.end(env)

absolutize_test = unittest.make(_absolutize_test)
tail_extraction_test = unittest.make(_tail_extraction_test)
find_flag_value_test = unittest.make(_find_flag_value_test)
fill_crossfile_from_toolchain_test = unittest.make(_fill_crossfile_from_toolchain_test)
move_dict_values_test = unittest.make(_move_dict_values_test)

def cmake_script_test_suite():
    unittest.suite(
        "cmake_script_test_suite",
        absolutize_test,
        tail_extraction_test,
        find_flag_value_test,
        fill_crossfile_from_toolchain_test,
        move_dict_values_test,
    )
