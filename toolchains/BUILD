toolchain(
    name = "prebuilt_ninja_toolchain_linux_x86_64",
    toolchain = "@rules_foreign_cc//toolchains/internal:ninja_tool_linux_x86_64",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:ninja_toolchain",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
)

toolchain(
    name = "prebuilt_ninja_toolchain_darwin_x86_64",
    toolchain = "@rules_foreign_cc//toolchains/internal:ninja_tool_darwin_x86_64",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:ninja_toolchain",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:macos",
    ],
)

toolchain(
    name = "prebuilt_cmake_toolchain_linux_x86_64",
    toolchain = "@rules_foreign_cc//toolchains/internal:cmake_tool_linux_x86_64",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:cmake_toolchain",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
)

toolchain(
    name = "prebuilt_cmake_toolchain_macos_universal",
    toolchain = "@rules_foreign_cc//toolchains/internal:cmake_tool_macos_universal",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:cmake_toolchain",
    exec_compatible_with = [
        "@platforms//os:macos",
    ],
)

toolchain(
    name = "prebuilt_cmake_toolchain_linux_aarch64",
    toolchain = "@rules_foreign_cc//toolchains/internal:cmake_tool_linux_aarch64",
    toolchain_type = "@rules_foreign_cc//tools/build_defs:cmake_toolchain",
    exec_compatible_with = [
        "@platforms//cpu:aarch64",
        "@platforms//os:linux",
    ],
)
