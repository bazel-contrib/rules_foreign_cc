tests = [
    "//cmake:test_libgd",
    "//cmake:test_libpng",
    "//cmake:test_zlib",
    "//cmake_cares:test_c_ares",
    "//cmake_cares:test_old_c_ares",
    "//cmake_hello_world_lib/static:test_hello",
    "//cmake_nghttp2:test_nghttp2",
    # Commented out because the paths in shell test should be different depending on whether it called
    # from out workspace or same workspace
    # Uncomment after nested workspaces are supported on CI
    #    "//built_ninja:test_ninja_version",
    "@rules_foreign_cc//test:cmake_script_test_suite",
    "//cc_configure_make:libevent_echosrv1",
]

test_suite(
    name = "tests",
    tests = tests + [
        "//cmake_synthetic:test_libs",
        "//configure_gnuplot:configure_libgd_tests",
        "//cmake_hello_world_lib/shared:test_libhello",
        "//cmake_hello_world_lib/binary:test_binary",
    ],
)

test_suite(
    name = "cmake_tests",
    tests = tests + [
        "//cmake_synthetic:test_libs",
        "//cmake_hello_world_lib/shared:test_libhello",
        "//cmake_hello_world_lib/binary:test_binary",
    ],
)

test_suite(
    name = "tests_no_synthetic",
    tests = tests + ["//configure_gnuplot:configure_libgd_tests"],
)

test_suite(
    name = "win_tests",
    tags = ["windows"],
    tests = tests + [
        "//cmake_synthetic:test_libs",
        "//configure_gnuplot:configure_libgd_tests",
        "//cmake_hello_world_lib/static:test_hello_ninja",
        "//cmake_hello_world_lib/static:test_hello_nmake",
    ],
)

# On Bazel CI Mac machines, we are using cmake built from sources
toolchain(
    name = "built_cmake_toolchain",
    exec_compatible_with = [
        "@bazel_tools//platforms:osx",
        "@bazel_tools//platforms:x86_64",
    ],
    toolchain = "@rules_foreign_cc//tools/build_defs/native_tools:built_cmake",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:cmake_toolchain",
)

# On Bazel CI Mac machines, we are using ninja built from sources
toolchain(
    name = "built_ninja_toolchain",
    toolchain = "@rules_foreign_cc//tools/build_defs/native_tools:built_ninja",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:ninja_toolchain",
)
