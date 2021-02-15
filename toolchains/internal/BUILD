load(
    "@rules_foreign_cc//tools/build_defs/native_tools:native_tools_toolchain.bzl",
    "native_tool_toolchain",
)

native_tool_toolchain(
    name = "ninja_tool_linux_x86_64",
    path = "ninja",
    target = "@ninja_linux_x86_64//:all_srcs",
)

native_tool_toolchain(
    name = "ninja_tool_darwin_x86_64",
    path = "ninja",
    target = "@ninja_darwin_x86_64//:all_srcs",
)

native_tool_toolchain(
    name = "ninja_tool_linux_aarch64",
    path = "ninja",
    target = "@ninja_src//:ninja",
)

native_tool_toolchain(
    name = "cmake_tool_linux_aarch64",
    path = "external/com_kitware_cmake_linux_aarch64/bin/cmake",
    target = "@com_kitware_cmake_linux_aarch64//:all_srcs",
)

native_tool_toolchain(
    name = "cmake_tool_linux_x86_64",
    path = "cmake",
    target = "@com_kitware_cmake_linux_x86_64//:all_srcs",
)

native_tool_toolchain(
    name = "cmake_tool_macos_universal",
    path = "cmake",
    target = "@com_kitware_cmake_macos_universal//:all_srcs",
)

native_tool_toolchain(
    name = "cmake_tool",
    path = "cmake",
    target = "@com_kitware_cmake_src//:cmake",
)
