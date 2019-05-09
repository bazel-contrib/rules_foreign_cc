load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

# Example of the cmake_external target built with Bazel-built dependency
cmake_external(
    name = "cmake_libb",
    cache_entries = {
        # as currently we copy all libraries, built with Bazel, into $EXT_BUILD_DEPS/lib
        # and the headers into $EXT_BUILD_DEPS/include
        "LIBA_DIR": "$EXT_BUILD_DEPS",
        # CMake's find_package wants to find cmake config for liba,
        # which we do not have -> disable search
        "CMAKE_DISABLE_FIND_PACKAGE_LIBA": "True",
    },
    cmake_options = ["-GNinja"],
    lib_source = "//cmake_with_bazel_transitive/libb:b_srcs",
    make_commands = [
        "ninja",
        "ninja install",
    ],
    static_libraries = ["libb.a"],
    # This library is with public visibility, we can reuse it here.
    deps = ["//cmake_synthetic/liba:lib_a_bazel"],
)

# And cc_test built with cmake_external dependency and transitive Bazel dependency
cc_test(
    name = "test",
    srcs = [
        "test_libb.cpp",
    ],
    deps = [
        # liba should come from transitive dependencies
        ":cmake_libb",
    ],
)
