tests = [
    "//examples/cmake:test_libgd",
    "//examples/cmake:test_libpng",
    "//examples/cmake:test_zlib",
    "//examples/cmake_cares:test_c_ares",
    "//examples/cmake_hello_world_lib/static:test_hello",
    "//examples/cmake_nghttp2:test_nghttp2",
    "//examples/ninja:test_ninja_version",
    "//test:cmake_script_test_suite",
    "//examples/cc_configure_make:libevent_echosrv1",
]

test_suite(
    name = "tests",
    tests = tests + [
        "//examples/cmake_synthetic:test_libs",
        "//examples/configure_gnuplot:configure_libgd_tests",
        "//examples/cmake_hello_world_lib/shared:test_libhello",
        "//examples/cmake_hello_world_lib/binary:test_binary",
    ],
)

test_suite(
    name = "cmake_tests",
    tests = tests + [
        "//examples/cmake_synthetic:test_libs",
        "//examples/cmake_hello_world_lib/shared:test_libhello",
        "//examples/cmake_hello_world_lib/binary:test_binary",
    ],
)

test_suite(
    name = "tests_no_synthetic",
    tests = tests + ["//examples/configure_gnuplot:configure_libgd_tests"],
)

test_suite(
    name = "win_tests",
    tags = ["windows"],
    tests = tests + [
        "//examples/cmake_synthetic:test_libs",
        "//examples/configure_gnuplot:configure_libgd_tests",
        "//examples/cmake_hello_world_lib/static:test_hello_ninja",
        "//examples/cmake_hello_world_lib/static:test_hello_nmake",
    ],
)
