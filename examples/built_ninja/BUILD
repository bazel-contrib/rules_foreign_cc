load("@rules_foreign_cc//for_workspace:ninja_build.bzl", "ninja_tool")

ninja_tool(
    name = "ninja_tool",
    ninja_srcs = "@ninja_build//:all",
)

sh_library(
    name = "ninja_",
    srcs = [":ninja_tool"],
)

sh_test(
    name = "test_ninja_version",
    srcs = ["test_ninja_version.sh"],
    args = ["true"],
    visibility = ["//:__pkg__"],
    deps = [":ninja_"],
)
