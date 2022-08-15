load("@rules_cc//cc:defs.bzl", "cc_binary")
load(":defs.bzl", "linux_kernel_headers")

linux_kernel_headers(
    name = "k151",
    kernel_version = "4.14.151",
    config = ":x86_64.config",
)

cc_binary(
    name = "example",
    srcs = ["example.c"],
    deps = [":k151"],
)

sh_test(
    name = "test_kernel_headers",
    srcs = ["test_kernel_headers.sh"],
    args = [
        "$(location :example)",
    ],
    data = [":example"],
    visibility = ["//:__pkg__"],
)
