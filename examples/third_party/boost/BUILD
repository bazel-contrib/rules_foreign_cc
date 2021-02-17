load("@rules_foreign_cc//tools/build_defs:boost_build.bzl", "boost_build")

boost_build(
    name = "boost_regex",
    bootstrap_options = ["--with-toolchain=clang"],
    lib_source = "@boost//:all",
    shared_libraries = ["libboost_regex.so.1.68.0"],
    static_libraries = ["libboost_regex.a"],
    user_options = ["--with-regex"],
)

boost_build(
    name = "boost_filesystem",
    lib_source = "@boost//:all",
    static_libraries = ["libboost_filesystem.a"],
    user_options = ["--with-filesystem"],
)
