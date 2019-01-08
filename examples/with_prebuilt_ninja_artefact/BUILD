load(
    "@rules_foreign_cc//tools/build_defs/native_tools:native_tools_toolchain.bzl",
    "native_tool_toolchain",
)
load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")

native_tool_toolchain(
    name = "ninja_tool",
    # In the path, we also start with the name of the directory,
    # in this case the external repository.
    path = "ninja_artefact/ninja",
    target = "@ninja_artefact//:all",
    visibility = ["//visibility:public"],
)

toolchain(
    name = "prebuilt_ninja_artefact_toolchain",
    toolchain = ":ninja_tool",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:ninja_toolchain",
)

cmake_external(
    name = "hello_cmake",
    cmake_options = ["-GNinja"],
    generate_crosstool_file = True,
    lib_source = "@examples//cmake_hello_world_lib/static:srcs",
    make_commands = [
        "ninja",
        "ninja install",
    ],
    out_include_dir = "include/version123",
    static_libraries = ["libhello.a"],
)
