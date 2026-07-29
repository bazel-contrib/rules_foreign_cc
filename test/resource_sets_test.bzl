"""Unit tests for the resource_size -> parallelism arithmetic."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:resource_sets.bzl", "parallelism_for")

def _resources(cpu, allow_cpu_overcommit = True):
    return struct(cpu = cpu, allow_cpu_overcommit = allow_cpu_overcommit)

# `resource_size = "default"` means no reservation, which has to stay
# distinguishable from "reserve one cpu" so callers leave the build system's
# own default alone rather than pinning it to -j1.
def _default_size_has_no_parallelism_test(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, 0, parallelism_for(_resources(cpu = 0), 2))

    return unittest.end(env)

def _overcommit_is_added_to_the_reservation_test(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, 3, parallelism_for(_resources(cpu = 1), 2))
    asserts.equals(env, 10, parallelism_for(_resources(cpu = 8), 2))
    asserts.equals(env, 8, parallelism_for(_resources(cpu = 8), 0))

    return unittest.end(env)

# Fixed-cpu sizes ("serial") exist for packages that break under parallelism,
# so the overcommit must not sneak back in.
def _fixed_cpu_sizes_ignore_overcommit_test(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, 1, parallelism_for(_resources(cpu = 1, allow_cpu_overcommit = False), 2))

    return unittest.end(env)

default_size_has_no_parallelism_test = unittest.make(_default_size_has_no_parallelism_test)
overcommit_is_added_to_the_reservation_test = unittest.make(_overcommit_is_added_to_the_reservation_test)
fixed_cpu_sizes_ignore_overcommit_test = unittest.make(_fixed_cpu_sizes_ignore_overcommit_test)

def resource_sets_test_suite():
    unittest.suite(
        "resource_sets_test_suite",
        partial.make(default_size_has_no_parallelism_test, size = "small"),
        partial.make(overcommit_is_added_to_the_reservation_test, size = "small"),
        partial.make(fixed_cpu_sizes_ignore_overcommit_test, size = "small"),
    )
