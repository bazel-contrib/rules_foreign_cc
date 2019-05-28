# example code is taken from https://github.com/Akagi201/learning-cmake/tree/master/hello-world-lib
# for test only

filegroup(
    name = "srcs",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)

load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

cmake_external(
    name = "libhello",
    lib_source = ":srcs",
    # pass include/version123 to C/C++ provider as include directory
    out_include_dir = "include/version123",
)

cmake_external(
    name = "libhello_win",
    cmake_options = ["-G \"Visual Studio 14 2015 Win64\""],
    generate_crosstool_file = True,
    lib_name = "libhello",
    lib_source = ":srcs",
    make_commands = ["MSBuild.exe INSTALL.vcxproj"],
    # pass include/version123 to C/C++ provider as include directory
    out_include_dir = "include/version123",
    static_libraries = ["hello.lib"],
)

cmake_external(
    name = "libhello_win_ninja",
    cmake_options = ["-GNinja"],
    generate_crosstool_file = True,
    lib_source = ":srcs",
    make_commands = [
        "ninja",
        "ninja install",
    ],
    # pass include/version123 to C/C++ provider as include directory
    out_include_dir = "include/version123",
    static_libraries = ["hello.lib"],
)

cmake_external(
    name = "libhello_win_nmake",
    cmake_options = ["-G \"NMake Makefiles\""],
    generate_crosstool_file = True,
    lib_source = ":srcs",
    make_commands = [
        "nmake",
        "nmake install",
    ],
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

cc_binary(
    name = "libhello_example_ninja",
    # includes just hello.h, include directory: "include/version123"
    srcs = ["hello_client.c"],
    deps = select({
        "@bazel_tools//src/conditions:windows": [":libhello_win_ninja"],
        "//conditions:default": [":libhello"],
    }),
)

cc_binary(
    name = "libhello_example_nmake",
    # includes just hello.h, include directory: "include/version123"
    srcs = ["hello_client.c"],
    deps = select({
        "@bazel_tools//src/conditions:windows": [":libhello_win_nmake"],
        "//conditions:default": [":libhello"],
    }),
)

sh_test(
    name = "test_hello",
    srcs = ["test_hello.sh"],
    args = ["$(location libhello_example)"],
    data = [":libhello_example"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
    tags = ["windows"],
    visibility = ["//:__pkg__"],
)

sh_test(
    name = "test_hello_ninja",
    srcs = ["test_hello.sh"],
    args = ["$(location libhello_example_ninja)"],
    data = [":libhello_example_ninja"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
    tags = ["windows"],
    visibility = ["//:__pkg__"],
)

sh_test(
    name = "test_hello_nmake",
    srcs = ["test_hello.sh"],
    args = ["$(location libhello_example_nmake)"],
    data = [":libhello_example_nmake"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
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
