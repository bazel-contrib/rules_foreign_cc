load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")
load("@bazel_skylib//rules:build_test.bzl", "build_test")

generate_crosstool = select({
    "@bazel_tools//src/conditions:windows": True,
    "//conditions:default": False,
})

cmake_external(
    name = "liba",
    cmake_options = ["-GNinja"],
    generate_crosstool_file = generate_crosstool,
    # Demonstrate non-alphanumeric name
    lib_name = "liba++",
    lib_source = "//cmake_synthetic/liba:a_srcs",
    make_commands = [
        "ninja",
        "ninja install",
    ],
    postfix_script = "cp $$INSTALLDIR$$/lib/liba.a $$INSTALLDIR$$/lib/liba++.a",
)

cmake_external(
    name = "libb",
    cmake_options = ["-GNinja"],
    generate_crosstool_file = generate_crosstool,
    lib_source = "//cmake_synthetic/libb:b_srcs",
    make_commands = [
        "ninja",
        "ninja install",
    ],
    deps = [":liba"],
)

cmake_external(
    name = "lib_with_duplicate_transitive_bazel_deps",
    lib_name = "libc",
    cmake_options = ["-GNinja"],
    cache_entries = {
        "LIBA_DIR": "$$EXT_BUILD_DEPS$$",
        "LIBB_DIR": "$$EXT_BUILD_DEPS$$",
    },
    generate_crosstool_file = generate_crosstool,
    lib_source = "//cmake_synthetic/libc:c_srcs",
    make_commands = [
        "ninja",
        "ninja install",
    ],
    deps = ["//cmake_synthetic/liba:lib_a_bazel", "//cmake_synthetic/libb:lib_b_bazel"],
)

build_test(
    name = "test_bazel_transitive_deps",
    targets = [":lib_with_duplicate_transitive_bazel_deps"],
)

cc_test(
    name = "test_libs",
    srcs = [
        "test_libb.cpp",
    ],
    tags = ["windows"],
    deps = [
        # liba should come from transitive dependencies
        ":libb",
    ],
)
