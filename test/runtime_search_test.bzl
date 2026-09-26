"""Aggregates runtime library search directory tests."""

load(
    ":runtime_search_paths_test.bzl",
    "runtime_library_search_directories_test_suite_paths",
)
load(
    ":runtime_search_policy_test.bzl",
    "runtime_library_search_directories_test_suite_policy",
)

def runtime_library_search_directories_test_suite(name = "runtime_library_search_directories_test_suite"):
    """Declares runtime-library-search helper and analysis-policy tests.

    Args:
      name: Name for the public aggregate test suite.
    """

    paths_suite = name + "_paths"
    policy_suite = name + "_policy"

    runtime_library_search_directories_test_suite_paths(name = paths_suite)
    runtime_library_search_directories_test_suite_policy(name = policy_suite)

    native.test_suite(
        name = name,
        tests = [
            paths_suite,
            policy_suite,
        ],
    )
