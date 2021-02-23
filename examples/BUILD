# TODO: This should not be necessary but there appears to be some inconsistent
# behavior with the use of `constraint_value`s in `select` statements. A support
# thread was started at the end of https://github.com/bazelbuild/bazel/pull/12071
# Once it is possible to replace `:windows` with `@platforms//os:windows` that
# should be done for this file. Note actioning on this will set the minimum
# supported version of Bazel to 4.0.0 for these examples.
config_setting(
    name = "windows",
    constraint_values = ["@platforms//os:windows"],
    visibility = ["//:__subpackages__"],
)

config_setting(
    name = "macos",
    constraint_values = ["@platforms//os:macos"],
    visibility = ["//:__subpackages__"],
)

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
    "//cc_configure_make:libevent_echosrv1",
    "//cmake_with_data:data_attr_tests",
]

test_suite(
    name = "tests",
    tests = tests + [
        "//apache_httpd:test",
        "//cmake_synthetic:test_libs",
        "//cmake_with_bazel_transitive:test",
        "//configure_gnuplot:configure_libgd_tests",
        "//configure_libunwind:configure_libunwind_tests",
        "//configure_mpc:configure_mpc_tests",
        "//cmake_hello_world_lib/shared:test_libhello",
        "//cmake_hello_world_lib/binary:test_binary",
        "//configure_with_bazel_transitive:test",
        "//simple_make:test_lib",
        "//cmake_hello_world_variant:test_hello_world",
        "//cmake_synthetic:test_bazel_transitive_deps",
        "//cmake_working_dir:test_lib",
    ],
)

test_suite(
    name = "mac_tests",
    tests = tests + [
        "//cmake_synthetic:test_libs",
        "//cmake_hello_world_lib/shared:test_libhello",
        "//cmake_hello_world_lib/binary:test_binary",
        "//simple_make:test_lib",
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
        #        "//cmake_synthetic:test_libs",
        #        "//configure_gnuplot:configure_libgd_tests",
        "//cmake_hello_world_lib/static:test_hello_ninja",
        "//cmake_hello_world_variant:test_hello_world",
        #        "//cmake_hello_world_lib/static:test_hello_nmake",
    ],
)

# On Bazel CI Mac machines, we are using ninja built from sources
toolchain(
    name = "built_ninja_toolchain_osx",
    exec_compatible_with = [
        "@platforms//os:macos",
        "@platforms//cpu:x86_64",
    ],
    toolchain = "@rules_foreign_cc//tools/build_defs/native_tools:built_ninja",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:ninja_toolchain",
)

toolchain(
    name = "built_ninja_toolchain_linux",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    toolchain = "@rules_foreign_cc//tools/build_defs/native_tools:built_ninja",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:ninja_toolchain",
)
