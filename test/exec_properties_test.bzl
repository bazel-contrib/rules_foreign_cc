"""Unit tests for the remote-execution exec_properties helper."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//foreign_cc:exec_properties.bzl", "foreign_cc_size_exec_properties")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:resource_sets.bzl", "SIZES", "size_exec_group_name")

_TWO_SIZES = {
    "large": struct(cpu = 8, mem = 1024),
    "tiny": struct(cpu = 1, mem = 250),
}

def _every_size_gets_a_property_test(ctx):
    env = unittest.begin(ctx)

    properties = foreign_cc_size_exec_properties(cpu_property = "EstimatedCPU")

    asserts.equals(env, len(SIZES), len(properties))
    for size in SIZES:
        asserts.true(
            env,
            size_exec_group_name(size) + ".EstimatedCPU" in properties,
            "missing a property for size " + size,
        )

    return unittest.end(env)

def _keys_are_scoped_to_the_exec_group_test(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        {
            "size_large.EstimatedCPU": "8",
            "size_large.EstimatedMemory": "1024M",
            "size_tiny.EstimatedCPU": "1",
            "size_tiny.EstimatedMemory": "250M",
        },
        foreign_cc_size_exec_properties(
            cpu_property = "EstimatedCPU",
            memory_property = "EstimatedMemory",
            memory_format = "{}M",
            sizes = _TWO_SIZES,
        ),
    )

    return unittest.end(env)

# Executors that only schedule on one dimension shouldn't be forced to declare
# the other.
def _properties_can_be_omitted_test(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        {"size_tiny.min-mem": "250"},
        foreign_cc_size_exec_properties(
            memory_property = "min-mem",
            sizes = {"tiny": struct(cpu = 1, mem = 250)},
        ),
    )

    return unittest.end(env)

every_size_gets_a_property_test = unittest.make(_every_size_gets_a_property_test)
keys_are_scoped_to_the_exec_group_test = unittest.make(_keys_are_scoped_to_the_exec_group_test)
properties_can_be_omitted_test = unittest.make(_properties_can_be_omitted_test)

def exec_properties_test_suite():
    unittest.suite(
        "exec_properties_test_suite",
        partial.make(every_size_gets_a_property_test, size = "small"),
        partial.make(keys_are_scoped_to_the_exec_group_test, size = "small"),
        partial.make(properties_can_be_omitted_test, size = "small"),
    )
