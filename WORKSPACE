workspace(name = "rules_foreign_cc")

all_content = """filegroup(name = "all", srcs = glob(["**"]), visibility = ["//visibility:public"])"""

new_http_archive(
    name = "bazel_skylib",
    build_file_content = all_content,
    sha256 = "b5f6abe419da897b7901f90cbab08af958b97a8f3575b0d3dd062ac7ce78541f",
    strip_prefix = "bazel-skylib-0.5.0",
    type = "tar.gz",
    urls = [
        "https://github.com/bazelbuild/bazel-skylib/archive/0.5.0.tar.gz",
    ],
)

new_http_archive(
    name = "libevent",
    build_file_content = all_content,
    strip_prefix = "libevent-2.1.8-stable",
    urls = ["https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz"],
)

new_http_archive(
    name = "zlib",
    build_file_content = all_content,
    sha256 = "4ff941449631ace0d4d203e3483be9dbc9da454084111f97ea0a2114e19bf066",
    strip_prefix = "zlib-1.2.11",
    urls = [
        "https://zlib.net/zlib-1.2.11.tar.xz",
    ],
)

new_http_archive(
    name = "libpng",
    build_file_content = all_content,
    sha256 = "2f1e960d92ce3b3abd03d06dfec9637dfbd22febf107a536b44f7a47c60659f6",
    strip_prefix = "libpng-1.6.34",
    urls = [
        "http://ftp-osl.osuosl.org/pub/libpng/src/libpng16/libpng-1.6.34.tar.xz",
    ],
)

new_http_archive(
    name = "org_linaro_components_toolchain_gcc_5_3_1",
    build_file = "framework_example/cmake_cross/compilers/linaro_linux_gcc_5.3.1.BUILD",
    strip_prefix = "gcc-linaro-5.3.1-2016.05-x86_64_arm-linux-gnueabihf",
    url = "https://bazel-mirror.storage.googleapis.com/releases.linaro.org/components/toolchain/binaries/latest-5/arm-linux-gnueabihf/gcc-linaro-5.3.1-2016.05-x86_64_arm-linux-gnueabihf.tar.xz",
)

http_archive(
    name = "bazel_toolchains",
    sha256 = "259ec05a457bc93aec2aee7e4e67fb4bc1724a183b67baaf5dd6a08be6d6a84a",
    strip_prefix = "bazel-toolchains-e76b1031eba14c16d72f5837ae7cb7630a2322e2",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-toolchains/archive/e76b1031eba14c16d72f5837ae7cb7630a2322e2.tar.gz",
        "https://github.com/bazelbuild/bazel-toolchains/archive/e76b1031eba14c16d72f5837ae7cb7630a2322e2.tar.gz",
    ],
)

android_sdk_repository(
    name = "androidsdk",
)

android_ndk_repository(
    name = "androidndk",
)

# Google Maven Repository
GMAVEN_TAG = "20180625-1"

http_archive(
    name = "gmaven_rules",
    strip_prefix = "gmaven_rules-%s" % GMAVEN_TAG,
    url = "https://github.com/bazelbuild/gmaven_rules/archive/%s.tar.gz" % GMAVEN_TAG,
)

load("@gmaven_rules//:gmaven.bzl", "gmaven_rules")

gmaven_rules()
