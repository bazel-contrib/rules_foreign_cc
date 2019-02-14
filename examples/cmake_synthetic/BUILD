load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

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
        "ninja",
        "ninja install",
    ],
)

cmake_external(
    name = "libb",
    cmake_options = ["-GNinja"],
    generate_crosstool_file = generate_crosstool,
    lib_source = "//cmake_synthetic/libb:b_srcs",
    make_commands = [
        "ninja",
        "ninja install",
    ],
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
