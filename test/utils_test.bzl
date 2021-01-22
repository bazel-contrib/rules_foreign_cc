""" Unit tests for some utility functions """

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//tools/build_defs:framework.bzl", "uniq_list_keep_order")

def _uniq_list_keep_order_test(ctx):
    env = unittest.begin(ctx)

    list = [1, 2, 3, 1, 4, 1, 2, 3, 5, 1, 2, 4, 7, 5]
    filtered = uniq_list_keep_order(list)
    asserts.equals(env, [1, 2, 3, 4, 5, 7], filtered)

    filteredEmpty = uniq_list_keep_order([])
    asserts.equals(env, [], filteredEmpty)

    return unittest.end(env)

uniq_list_keep_order_test = unittest.make(_uniq_list_keep_order_test)

def utils_test_suite():
    unittest.suite(
        "utils_test_suite",
        uniq_list_keep_order_test,
    )
