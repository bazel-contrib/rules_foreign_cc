load("//tools/build_defs:cmake.bzl", "cmake_external")

cmake_external(
    name = "pybind11",
    cmake_options = ["-DPYBIND11_TEST=False"],
    headers_only = True,
    lib_source = "@pybind11//:all",
    out_config_dirs = ["share/cmake/pybind11"],
    tools_deps = ["@pytest//:all"],
)

filegroup(
    name = "example_src",
    srcs = glob(["example/**"]),
)

cmake_external(
    name = "example_bind",
    # include system headers, change this to appropriate value
    env_vars = {"CXXFLAGS": "-isystem=/usr/include/python2.7"},
    lib_source = ":example_src",
    shared_libraries = ["example.cpython-35m-x86_64-linux-gnu.so"],
    deps = [
        ":pybind11",
    ],
)

#sh_test(
#    name = "call_cpp_from_py",
#    srcs = ["call_cpp_from_py.sh"],
#    data = [
#        "test.py",
#        ":example_bind",
#    ],
#)
