"""Expected-failure tests for shared-library conflict behavior."""

load("//test:facade_test_utils.bzl", analysis_smoke_test_impl = "analysis_smoke_test", expect_failure_test_impl = "expect_failure_test")

def analysis_smoke_test(*, name, target):
    analysis_smoke_test_impl(
        name = name,
        target = target,
    )

def expect_failure_test(*, name, target, failure_message):
    expect_failure_test_impl(
        name = name,
        target = target,
        failure_message = failure_message,
    )
