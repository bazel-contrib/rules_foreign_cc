# example code is taken from https://github.com/Akagi201/learning-cmake/tree/master/hello-world-lib
# for test only

filegroup(
    name = "srcs",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)

load("//tools/build_defs:cmake.bzl", "cmake_external")

cmake_external(
    name = "libhello",
    lib_source = ":srcs",
    # pass include/version123 to C/C++ provider as include directory
    out_include_dir = "include/version123",
)

cmake_external(
    name = "libhello_win",
    cmake_options = ["-G \"Visual Studio 15 2017 Win64\""],
    generate_crosstool_file = True,
    lib_source = ":srcs",
    make_commands = ["MSBuild.exe INSTALL.vcxproj"],
    # pass include/version123 to C/C++ provider as include directory
    out_include_dir = "include/version123",
    static_libraries = ["hello.lib"],
)

cc_binary(
    name = "libhello_example",
    # includes just hello.h, include directory: "include/version123"
    srcs = ["hello_client.c"],
    deps = select({
        "@bazel_tools//src/conditions:windows": [":libhello_win"],
        "//conditions:default": [":libhello"],
    }),
)

sh_test(
    name = "test_hello",
    srcs = ["test_hello.sh"],
    data = [":libhello_example"],
    tags = ["windows"],
    visibility = ["//:__pkg__"],
)

cmake_external(
    name = "libhello123",
    lib_source = ":srcs",
    out_include_dir = "include",
    # the name of the static library != <name>.a, put it explicitly
    static_libraries = ["libhello.a"],
)

cc_binary(
    name = "libhello_example123",
    # includes version123/hello.h, include directory: "include"
    srcs = ["hello_client_version123.c"],
    deps = [":libhello123"],
)
