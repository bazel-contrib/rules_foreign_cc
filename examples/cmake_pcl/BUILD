load("@rules_foreign_cc//tools/build_defs:cmake.bzl", "cmake_external")
load("@rules_foreign_cc//tools/build_defs:boost_build.bzl", "boost_build")

# This takes something about 10 minutes
boost_build(
    name = "boost",
    lib_source = "@boost//:all",
    static_libraries = [
        "libboost_atomic.a",
        "libboost_chrono.a",
        "libboost_container.a",
        "libboost_context.a",
        "libboost_contract.a",
        "libboost_coroutine.a",
        "libboost_date_time.a",
        "libboost_exception.a",
        "libboost_fiber.a",
        "libboost_filesystem.a",
        "libboost_graph.a",
        "libboost_iostreams.a",
        "libboost_locale.a",
        "libboost_log.a",
        "libboost_log_setup.a",
        "libboost_math_c99.a",
        "libboost_math_c99f.a",
        "libboost_math_c99l.a",
        "libboost_math_tr1.a",
        "libboost_math_tr1f.a",
        "libboost_math_tr1l.a",
        "libboost_numpy27.a",
        "libboost_prg_exec_monitor.a",
        "libboost_program_options.a",
        "libboost_python27.a",
        "libboost_random.a",
        "libboost_regex.a",
        "libboost_serialization.a",
        "libboost_signals.a",
        "libboost_stacktrace_addr2line.a",
        "libboost_stacktrace_backtrace.a",
        "libboost_stacktrace_basic.a",
        "libboost_stacktrace_noop.a",
        "libboost_system.a",
        "libboost_test_exec_monitor.a",
        "libboost_thread.a",
        "libboost_timer.a",
        "libboost_type_erasure.a",
        "libboost_unit_test_framework.a",
        "libboost_wave.a",
        "libboost_wserialization.a",
    ],
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
    lib_source = "@eigen//:all",
    out_include_dir = "include/eigen3",
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
        ":boost",
        ":eigen",
        ":flann",
    ],
)
