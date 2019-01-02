tests = [
    "//cmake:test_libgd",
    "//cmake:test_libpng",
    "//cmake:test_zlib",
    "//cmake_cares:test_c_ares",
    "//cmake_hello_world_lib/static:test_hello",
    "//cmake_nghttp2:test_nghttp2",
    "//ninja:test_ninja_version",
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
