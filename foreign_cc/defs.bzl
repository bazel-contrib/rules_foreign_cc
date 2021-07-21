"""Public entry point to all Foreign CC rules and supported APIs."""

load(":boost_build.bzl", _boost_build = "boost_build")
load(":cmake.bzl", _cmake = "cmake")
load(":configure.bzl", _configure_make = "configure_make", _configure_nmake = "configure_nmake")
load(":make.bzl", _make = "make")
load(":ninja.bzl", _ninja = "ninja")

boost_build = _boost_build
cmake = _cmake
configure_make = _configure_make
configure_nmake = _configure_nmake
make = _make
ninja = _ninja
