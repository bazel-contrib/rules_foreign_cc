# This is the entry point for --crosstool_top.  Toolchains are found
# by lopping off the name of --crosstool_top and searching for
# 'cc-compiler-${CPU}' in this BUILD file, where CPU is the target CPU
# specified in --cpu.
#

cc_toolchain_suite(
    name = "toolchain",
    # target_cpu | compiler
    toolchains = {
        "armeabi-v7a|gcc": "cc-compiler-armeabi-v7a",
        "k8|compiler": "cc-compiler-k8",
    },
)

filegroup(
    name = "linaro_linux_all_files",
    srcs = [
        "//framework_example/cmake_cross/tools/arm_compiler/linaro_linux_gcc:tool-wrappers",
        "@org_linaro_components_toolchain_gcc_5_3_1//:compiler_pieces",
    ],
)

filegroup(
    name = "linaro_linux_linker_files",
    srcs = [
        "//framework_example/cmake_cross/tools/arm_compiler/linaro_linux_gcc:ar",
        "//framework_example/cmake_cross/tools/arm_compiler/linaro_linux_gcc:gcc",
        "//framework_example/cmake_cross/tools/arm_compiler/linaro_linux_gcc:ld",
        "@org_linaro_components_toolchain_gcc_5_3_1//:compiler_pieces",
    ],
)

filegroup(
    name = "linaro_linux_compiler_files",
    srcs = [
        "//framework_example/cmake_cross/tools/arm_compiler/linaro_linux_gcc:as",
        "//framework_example/cmake_cross/tools/arm_compiler/linaro_linux_gcc:gcc",
        "//framework_example/cmake_cross/tools/arm_compiler/linaro_linux_gcc:ld",
    ],
)

filegroup(
    name = "empty",
    srcs = [],
)

cc_toolchain(
    name = "cc-compiler-armeabi-v7a",
    all_files = ":linaro_linux_all_files",
    ar_files = "//framework_example/cmake_cross/tools/arm_compiler/linaro_linux_gcc:ar",
    as_files = "//framework_example/cmake_cross/tools/arm_compiler/linaro_linux_gcc:as",
    compiler_files = ":linaro_linux_compiler_files",
    cpu = "armeabi-v7a",
    dwp_files = ":empty",
    dynamic_runtime_libs = [":empty"],
    linker_files = ":linaro_linux_linker_files",
    objcopy_files = "//framework_example/cmake_cross/tools/arm_compiler/linaro_linux_gcc:objcopy",
    static_runtime_libs = [":empty"],
    strip_files = "//framework_example/cmake_cross/tools/arm_compiler/linaro_linux_gcc:strip",
    supports_param_files = 1,
    visibility = ["//visibility:public"],
)

cc_toolchain(
    name = "cc-compiler-k8",
    all_files = ":empty",
    ar_files = ":empty",
    as_files = ":empty",
    compiler_files = ":empty",
    cpu = "local",
    dwp_files = ":empty",
    dynamic_runtime_libs = [":empty"],
    linker_files = ":empty",
    objcopy_files = ":empty",
    static_runtime_libs = [":empty"],
    strip_files = ":empty",
    supports_param_files = 1,
)
