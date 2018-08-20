workspace(name = "rules_foreign_cc")

load("//:workspace_definitions.bzl", "rules_foreign_cc_dependencies")

rules_foreign_cc_dependencies()

all_content = """filegroup(name = "all", srcs = glob(["**"]), visibility = ["//visibility:public"])"""

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

new_http_archive(
    name = "freetype",
    build_file_content = all_content,
    sha256 = "e6ffba3c8cef93f557d1f767d7bc3dee860ac7a3aaff588a521e081bc36f4c8a",
    strip_prefix = "freetype-2.9",
    urls = [
        "https://download.savannah.gnu.org/releases/freetype/freetype-2.9.tar.bz2",
    ],
)

new_http_archive(
    name = "libgd",
    build_file_content = all_content,
    sha256 = "8c302ccbf467faec732f0741a859eef4ecae22fea2d2ab87467be940842bde51",
    strip_prefix = "libgd-2.2.5",
    urls = [
        "https://github.com/libgd/libgd/releases/download/gd-2.2.5/libgd-2.2.5.tar.xz",
    ],
)

new_http_archive(
    name = "pybind11",
    build_file_content = all_content,
    strip_prefix = "pybind11-2.2.3",
    url = "https://github.com/pybind/pybind11/archive/v2.2.3.tar.gz",
)

new_http_archive(
    name = "ninja_build",
    build_file_content = all_content,
    sha256 = "86b8700c3d0880c2b44c2ff67ce42774aaf8c28cbf57725cb881569288c1c6f4",
    strip_prefix = "ninja-1.8.2",
    urls = [
        "https://github.com/ninja-build/ninja/archive/v1.8.2.tar.gz",
    ],
)
