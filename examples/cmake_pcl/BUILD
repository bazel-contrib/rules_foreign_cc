load("//tools/build_defs:cmake.bzl", "cmake_external")

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
    lib_source = "@eigen//:all",
    deps = [":openblas"],
)

cmake_external(
    name = "flann",
    cache_entries = {
    },
    lib_source = "@flann//:all",
    static_libraries = [
        "libflann_s.a",
        "libflann_cpp_s.a",
    ],
)

# todo additional dependencies needed
cmake_external(
    name = "pcl",
    cache_entries = {
        "WITH_LIBUSB": "no",
        "EIGEN_INCLUDE_DIR": "$EXT_BUILD_DEPS/eigen/include",
        "FLANN_LIBRARY": "$EXT_BUILD_DEPS/flann/lib/libflann_s.a",
        "FLANN_INCLUDE_DIR": "$EXT_BUILD_DEPS/flann/include",
    },
    cmake_options = ["-DBUILD_WITH_OPENMP=False"],
    headers_only = True,
    lib_source = "@pcl//:all",
    deps = [
        ":eigen",
        ":flann",
    ],
)
