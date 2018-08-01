load("//tools/build_defs:cmake.bzl", "cmake_external")
load("@gmaven_rules//:defs.bzl", "gmaven_artifact")

cmake_external(
    name = "libz",
    additional_tools = [
        "@androidsdk//:files",
        "@androidndk//:files",
    ],
    lib_source = "@zlib//:all",
)

cc_library(
    name = "test_zlib",
    srcs = ["zlib-example.cpp"],
    deps = ["libz"],
)

android_library(
    name = "lib",
    srcs = ["java/com/example/android/bazel/MainActivity.java"],
    custom_package = "com.example.android.bazel",
    manifest = "LibraryManifest.xml",
    resource_files = glob(["res/**/*"]),
    deps = [
        ":test_zlib",
        gmaven_artifact("com.android.support:appcompat-v7:aar:26.1.0"),
        gmaven_artifact("com.android.support.constraint:constraint-layout:aar:1.1.2"),
    ],
)

android_binary(
    name = "app",
    custom_package = "com.example.android.bazel",
    manifest = "AndroidManifest.xml",
    deps = [":lib"],
)
