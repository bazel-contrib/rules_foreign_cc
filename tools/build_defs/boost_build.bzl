""" Rule for building Boost from sources. """

load("//foreign_cc:defs.bzl", _boost_build = "boost_build")
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

boost_build = _boost_build
