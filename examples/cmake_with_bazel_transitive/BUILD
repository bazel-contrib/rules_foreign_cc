load("@rules_cc//cc:defs.bzl", "cc_test")
load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

# Example of the cmake_external target built with Bazel-built dependency
cmake_external(
    name = "cmake_libb",
    cache_entries = {
        # CMake's find_package wants to find cmake config for liba,
        # which we do not have -> disable search
        "CMAKE_DISABLE_FIND_PACKAGE_LIBA": "True",
        # as currently we copy all libraries, built with Bazel, into $EXT_BUILD_DEPS/lib
        # and the headers into $EXT_BUILD_DEPS/include
        "LIBA_DIR": "$EXT_BUILD_DEPS",
        "LIBA_PATH": "$EXT_BUILD_DEPS/lib/liba.a",
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

cmake_external(
    name = "cmake_libb_shared",
    cache_entries = {
        "BUILD_SHARED_LIBS": "ON",
        "CMAKE_SHARED_LIBRARY_SUFFIX_CXX": ".so", # easier consistency on macos
        "CMAKE_MACOSX_RPATH": "True",
        # CMake's find_package wants to find cmake config for liba,
        # which we do not have -> disable search
        "CMAKE_DISABLE_FIND_PACKAGE_LIBA": "True",
        # as currently we copy all libraries, built with Bazel, into $EXT_BUILD_DEPS/lib
        # and the headers into $EXT_BUILD_DEPS/include
        "LIBA_DIR": "$EXT_BUILD_DEPS",
        #"LIBA_PATHx": "$EXT_BUILD_DEPS/lib/liba.so",
    },
    cmake_options = ["-GNinja", "--trace", "--debug-find"],
    lib_source = "//cmake_with_bazel_transitive/libb:b_srcs",
    make_commands = [
        "ninja",
        "ninja install",
    ],
    shared_libraries = ["libb.so"],
    deps = ["//cmake_synthetic/liba:lib_a_so"],
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

# And cc_test built with cmake_external shared dependency and transitive shared Bazel dependency
cc_test(
    name = "test_shared",
    srcs = [
        "test_libb.cpp",
    ],
    deps = [
        # liba should come from transitive dependencies
        ":cmake_libb_shared",
    ],
)
