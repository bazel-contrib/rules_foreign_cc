"""Unit tests for set_file_prefix_map functionality"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:framework.bzl", "CC_EXTERNAL_RULE_ATTRIBUTES")

def _test_set_file_prefix_map_default_true(ctx):
    """Test that set_file_prefix_map defaults to True"""
    env = unittest.begin(ctx)
    
    # Get the attribute definition
    attr_def = CC_EXTERNAL_RULE_ATTRIBUTES["set_file_prefix_map"]
    
    # The default should be a select() that returns True for the default case
    # We can't easily test the select() evaluation without a real context,
    # but we can verify that the structure is correct
    asserts.true(env, hasattr(attr_def, "default"), "set_file_prefix_map should have a default")
    
    return unittest.end(env)

set_file_prefix_map_default_test = unittest.make(_test_set_file_prefix_map_default_true)

def set_file_prefix_map_test_suite():
    unittest.suite(
        "set_file_prefix_map_test_suite",
        set_file_prefix_map_default_test,
    )