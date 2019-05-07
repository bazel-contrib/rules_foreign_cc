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
        # liba should come from transitive dependencies
        ":libb",
    ],
)

# Example of the cmake_external target built with Bazel-built dependency
cmake_external(
    name = "cmake_using_bazel_dep",
    cache_entries = {
        # as currently we copy all libraries, built with Bazel, into $EXT_BUILD_DEPS/lib
        # and the headers into $EXT_BUILD_DEPS/include
        "LIBA_DIR": "$EXT_BUILD_DEPS",
        # CMake's find_package wants to find cmake config for liba,
        # which we do not have -> disable search
        "CMAKE_DISABLE_FIND_PACKAGE_LIBA": "True",
    },
    cmake_options = ["-GNinja"],
    generate_crosstool_file = generate_crosstool,
    lib_source = "//cmake_synthetic/cmake_using_bazel_dep:b_srcs",
    make_commands = [
        "ninja",
        "ninja install",
    ],
    static_libraries = ["libb.a"],
    deps = ["//cmake_synthetic/liba:lib_a_bazel"],
)

# And cc_test built with cmake_external dependency and transitive Bazel dependency
cc_test(
    name = "test_libs_bazel_transitive_from_cmake",
    srcs = [
        "test_libb.cpp",
    ],
    tags = ["windows"],
    deps = [
        # liba should come from transitive dependencies
        ":cmake_using_bazel_dep",
    ],
)
