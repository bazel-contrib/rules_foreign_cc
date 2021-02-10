exports_files(["clang_wrapper.sh"])

filegroup(
    name = "sources",
    srcs = glob(
        ["**"],
        exclude = ["clang_wrapper.sh"],
    ),
    visibility = ["//simple_make:__subpackages__"],
)
