load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")
load("@foreign_cc_platform_utils//:tools.bzl", "NINJA_COMMAND", "NINJA_DEP")

filegroup(
    name = "b_srcs",
    srcs = glob(["libb/**"]),
    visibility = ["//visibility:public"],
)

generate_crosstool = select({
    "@bazel_tools//src/conditions:windows": True,
    "//conditions:default": False,
})

cmake_external(
    name = "liba",
    cmake_options = ["-GNinja"],
    generate_crosstool_file = generate_crosstool,
    lib_source = "//cmake_synthetic/liba:a_srcs",
    make_commands = [
        NINJA_COMMAND,
        NINJA_COMMAND + " install",
    ],
    tools_deps = NINJA_DEP,
)

cmake_external(
    name = "libb",
    cmake_options = ["-GNinja"],
    generate_crosstool_file = generate_crosstool,
    lib_source = "//cmake_synthetic/libb:b_srcs",
    make_commands = [
        NINJA_COMMAND,
        NINJA_COMMAND + " install",
    ],
    tools_deps = NINJA_DEP,
    deps = [":liba"],
)

cc_test(
    name = "test_libs",
    srcs = [
        "test_libb.cpp",
    ],
    tags = ["windows"],
    deps = [
        ":liba",
        ":libb",
    ],
)
