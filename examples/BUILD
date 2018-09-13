tests = [
    "//examples/cmake:test_libgd",
    "//examples/cmake:test_libpng",
    "//examples/cmake:test_zlib",
    "//examples/cmake_cares:test_c_ares",
    "//examples/cmake_hello_world_lib:test_hello",
    "//examples/cmake_nghttp2:test_nghttp2",
    "//examples/ninja:test_ninja_version",
    "//test:cmake_script_test_suite",
    "//examples/cmake_synthetic:test_libs",
]

test_suite(
    name = "tests",
    tests = tests,
)

test_suite(
    name = "win_tests",
    tags = ["windows"],
    tests = tests + [
        "//examples/cmake_hello_world_lib:test_hello_ninja",
        "//examples/cmake_hello_world_lib:test_hello_nmake",
    ],
)
