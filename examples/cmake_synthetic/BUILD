load("//tools/build_defs:cmake.bzl", "cmake_external")
load("@foreign_cc_platform_utils//:tools.bzl", "NINJA_COMMAND", "NINJA_DEP")

filegroup(
    name = "b_srcs",
    srcs = glob(["libb/**"]),
    visibility = ["//visibility:public"],
)

cmake_external(
    name = "liba",
    cmake_options = ["-GNinja"],
    lib_source = "//examples/cmake_synthetic/liba:a_srcs",
    make_commands = [
        NINJA_COMMAND,
        NINJA_COMMAND + " install",
    ],
    static_libraries = ["libliba.a"],
    tools_deps = NINJA_DEP,
)

cmake_external(
    name = "libb",
    cmake_options = ["-GNinja"],
    lib_source = "//examples/cmake_synthetic/libb:b_srcs",
    make_commands = [
        NINJA_COMMAND,
        NINJA_COMMAND + " install",
    ],
    static_libraries = ["liblibb.a"],
    tools_deps = NINJA_DEP,
    deps = [":liba"],
)

cc_test(
    name = "test_libs",
    srcs = [
        "test_libb.cpp",
    ],
    deps = [
        ":liba",
        ":libb",
    ],
)
