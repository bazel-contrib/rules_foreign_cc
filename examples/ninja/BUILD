load("//tools/build_defs:ninja_build.bzl", "ninja_tool")

ninja_tool(
    name = "ninjatool",
    ninja_srcs = "@ninja_build//:all",
)

sh_library(
    name = "ninja",
    srcs = [":ninjatool"],
)

sh_test(
    name = "test_ninja_version",
    srcs = ["test_ninja_version.sh"],
    visibility = ["//:__pkg__"],
    deps = [":ninja"],
)
