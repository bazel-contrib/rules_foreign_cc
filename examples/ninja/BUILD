load("@foreign_cc_platform_utils//:tools.bzl", "NINJA_USE_BUILT", "NINJA_DEP")

sh_test(
    name = "test_ninja_version",
    srcs = ["test_ninja_version.sh"],
    args = ["true" if NINJA_USE_BUILT else "false"],
    visibility = ["//:__pkg__"],
    deps = NINJA_DEP,
)
