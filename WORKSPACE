workspace(name = "rules_foreign_cc")

all_content = """filegroup(name = "all", srcs = glob(["**"]), visibility = ["//visibility:public"])"""

new_http_archive(
      name = "bazel_skylib",
      urls = [
          "https://github.com/bazelbuild/bazel-skylib/archive/0.5.0.tar.gz",
      ],
      strip_prefix= "bazel-skylib-0.5.0",
      sha256 = "b5f6abe419da897b7901f90cbab08af958b97a8f3575b0d3dd062ac7ce78541f",
      type = "tar.gz",
      build_file_content = all_content,
  )

new_http_archive(
    name = "libevent",
    build_file_content = all_content,
    strip_prefix = "libevent-2.1.8-stable",
    urls = ["https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz"],
)

new_http_archive(
      name = "zlib",
      urls = [
          "https://zlib.net/zlib-1.2.11.tar.xz",
      ],
      strip_prefix= "zlib-1.2.11",
      sha256 = "4ff941449631ace0d4d203e3483be9dbc9da454084111f97ea0a2114e19bf066",
      build_file_content = all_content,
  )

new_http_archive(
      name = "libpng",
      urls = [
          "http://ftp-osl.osuosl.org/pub/libpng/src/libpng16/libpng-1.6.34.tar.xz",
      ],
      strip_prefix= "libpng-1.6.34",
      sha256 = "2f1e960d92ce3b3abd03d06dfec9637dfbd22febf107a536b44f7a47c60659f6",
      build_file_content = all_content,
  )