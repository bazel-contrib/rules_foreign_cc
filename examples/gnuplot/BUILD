load("//cc_configure_make:cc_configure_make.bzl", "cc_configure_make_tmp_macros",
  "cc_configure_make_binary_tmp_macros")

cc_configure_make_tmp_macros(
    name = "zlib",
    srcs = "@zlib//:all",
    configure_flags = [],
    out_lib_name = "libz.a",
)

cc_configure_make_tmp_macros(
    name = "libpng",
    srcs = "@libpng//:all",
    configure_flags = [
        "--disable-shared",
        "--with-zlib-prefix=$root(zlib)"
    ],
    deps = [
        "zlib",
    ],
    out_lib_name = "libpng16.a",
)

cc_configure_make_tmp_macros(
    name = "freetype",
    srcs = "@freetype//:all",
    configure_flags = [
        "--disable-shared",
        "--with-bzip2=no",
        "--with-png=$root(libpng)",
        "--with-zlib=$root(zlib)"
    ],
    deps = [
        "libpng",
        "zlib",
    ],
    out_include_folder = "include/freetype2",
    out_lib_name = "libfreetype.a",
)

cc_configure_make_tmp_macros(
    name = "libgd",
    srcs = "@libgd//:all",
    configure_flags = [
        "--disable-shared",
        "--with-freetype=$root(freetype)",
        "--with-png=$root(libpng)",
        "--with-zlib=$root(zlib)",
    ],
    deps = [
        "freetype",
        "libpng",
        "zlib",
    ],
)

cc_binary(
    name = "test_libgd_with_png",
    srcs = ["arc.c"],
    defines = ["HAVE_LIBPNG"],
    deps = ["libgd", "freetype", "libpng", "zlib"]
)

cc_configure_make_binary_tmp_macros(
    name = "gnuplot",
    srcs = "@gnuplot//:all",
    configure_flags = [
#        "--disable-shared",
#        "--disable-plugins",

        # https://sourceforge.net/p/gnuplot/bugs/2024/
        "--with-texdir=$tmpinstalldir",

        "--with-gd=$root(libgd)",
    ],
    deps = [
"libgd", "freetype", "libpng", "zlib"    ],
    out_lib_folder = "bin",
    out_lib_name = "gnuplot",
    out_pkg_config_folder = False
)

# this does not work, but invoking gnuplot from the build library works
genrule(
    name = "run_gnuplot_test",
    cmd = "$(location gnuplot) -c $(location example.txt)",
    outs = ["image.png"],
    tools = [":gnuplot", "example.txt"],
)

# this does not work, but invoking gnuplot from the build library works
sh_binary(
    name = "run_gnuplot",
    srcs = [":gnuplot"],
    data = [":gnuplot", "example.txt", ":zlib",
                                              ":libpng",
                                              ":freetype",
                                              ":libgd",],
    args = ["-c", "$(location example.txt)"],
)

cc_binary(
    name = "libpng_test",
    srcs = ["libpng_test.cpp"],
    args = ["$(location bazel-icon-transparent.png) out.png"],
    data = ["bazel-icon-transparent.png"],
    deps = ["libpng", "zlib"],
)

cc_binary(
    name = "libgd_resize_test",
    srcs = ["libgd_resize.c"],
    args = ["$(location bazel-icon-transparent.png) out_resize.png 32 32"],
    data = ["bazel-icon-transparent.png"],
    deps = ["libgd", "freetype", "libpng", "zlib"],
    defines = ["HAVE_LIBPNG"],
)
