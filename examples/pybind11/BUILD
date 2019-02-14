load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

cmake_external(
    name = "pybind11",
    # turn off testing
    cmake_options = ["-DPYBIND11_TEST=False"],
    headers_only = True,
    lib_source = "@pybind11//:all",
)

filegroup(
    name = "example_src",
    srcs = glob(["example/**"]),
)

cmake_external(
    name = "example_bind",
    # include system headers, change this to appropriate value
    env_vars = {
        "CXXFLAGS": "-isystem=/usr/include/python2.7 -fPIC",
        "CFLAGS": "-isystem=/usr/include/python2.7 -fPIC",
    },
    lib_source = ":example_src",
    shared_libraries = ["example.cpython-35m-x86_64-linux-gnu.so"],
    deps = [
        ":pybind11",
    ],
)
