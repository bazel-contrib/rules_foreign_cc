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


new_http_archive(
      name = "freetype",
      urls = [
          "https://download.savannah.gnu.org/releases/freetype/freetype-2.9.tar.bz2",
      ],
      strip_prefix = "freetype-2.9",
      sha256 = "e6ffba3c8cef93f557d1f767d7bc3dee860ac7a3aaff588a521e081bc36f4c8a",
      build_file_content = all_content,
  )

new_http_archive(
      name = "libgd",
      urls = [
          "https://github.com/libgd/libgd/releases/download/gd-2.2.5/libgd-2.2.5.tar.xz",
      ],
      strip_prefix = "libgd-2.2.5",
      sha256 = "8c302ccbf467faec732f0741a859eef4ecae22fea2d2ab87467be940842bde51",
      build_file_content = all_content,
  )

new_http_archive(
      name = "gnuplot",
      urls = [
          "https://sourceforge.net/projects/gnuplot/files/gnuplot/5.2.4/gnuplot-5.2.4.tar.gz/download",
          "http://download.openpkg.org/components/cache/gnuplot/gnuplot-5.2.4.tar.gz",
      ],
      strip_prefix = "gnuplot-5.2.4",
      type = "tar.gz",
      sha256 = "1515f000bd373aaa53b16183f274189d4f5e0ae47d22f434857933d16a4770cb",
      build_file_content = all_content,
  )