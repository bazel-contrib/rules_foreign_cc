load("//tools/build_defs:cmake.bzl", "cmake_external")
load("//tools/build_defs:boost_build.bzl", "boost_build")

# This takes something about 10 minutes
boost_build(
    name = "boost",
    lib_source = "@boost//:all"
)

cmake_external(
    name = "openblas",
    cache_entries = {
        "NOFORTRAN": "on",
        "BUILD_WITHOUT_LAPACK": "no",
    },
    lib_source = "@openblas//:all",
    static_libraries = ["libopenblas.a"],
)

cmake_external(
    name = "eigen",
    cache_entries = {
        "BLA_VENDOR": "OpenBLAS",
        "BLAS_LIBRARIES": "$EXT_BUILD_DEPS/openblas/lib/libopenblas.a",
    },
    headers_only = True,
    out_include_dir = "include/eigen3",
    lib_source = "@eigen//:all",
    deps = [":openblas"],
)


cmake_external(
    name = "flann",
    lib_source = "@flann//:all",
    static_libraries = ["libflann_s.a"],
)

# This takes about an hour
cmake_external(
    name = "pcl",
    cache_entries = {
        "WITH_LIBUSB": "no",
        "EIGEN_INCLUDE_DIRS": "$EXT_BUILD_DEPS/eigen/include/eigen3",
        "EIGEN_INCLUDE_DIR": "$EXT_BUILD_DEPS/eigen/include/eigen3",
        "FLANN_LIBRARY": "$EXT_BUILD_DEPS/flann/lib/libflann_s.a",
        "FLANN_INCLUDE_DIRS": "$EXT_BUILD_DEPS/flann/include",
        "FLANN_INCLUDE_DIR": "$EXT_BUILD_DEPS/flann/include",
        "WITH_PNG": "no",
        "WITH_QHULL": "no",
        "WITH_CUDA": "no",
        "WITH_QT": "no",
        "WITH_VTK": "no",
        "WITH_PCAP": "no",
        "WITH_OPENGL": "no",
        "WITH_OPENNI": "no",
        "WITH_OPENNI2": "no",
        "WITH_FZAPI": "no",
        "WITH_ENSENSO": "no",
        "WITH_DAVIDSDK": "no",
        "WITH_DSSDK": "no",
        "WITH_RSSDK": "no",
        "BOOST_ROOT": "$EXT_BUILD_DEPS/boost/",
        "BOOST_INCLUDEDIR": "$EXT_BUILD_DEPS/boost/include",
    },
    headers_only = True,
    lib_source = "@pcl//:all",
    out_include_dir = "include/pcl-1.8",
    deps = [
        ":eigen",
        ":flann",
        ":boost"
    ],
)