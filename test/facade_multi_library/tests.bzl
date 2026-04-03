"""Analysis tests for explicit multi-library foreign_cc facade selection."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_cc//cc:defs.bzl", "CcInfo")
load("//test:facade_test_utils.bzl", "cc_library_summary", "default_runfiles_basenames", "expect_failure_test", "selected_cc_library")

def _selected_foreign_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    library = selected_cc_library(target)

    asserts.equals(env, ctx.attr.expected_dynamic, library.dynamic)
    asserts.equals(env, ctx.attr.expected_static, library.static)
    asserts.equals(env, sorted(ctx.attr.expected_runfiles), default_runfiles_basenames(target))

    return analysistest.end(env)

def _matches_cc_import_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    control = ctx.attr.control

    asserts.equals(env, cc_library_summary(control), cc_library_summary(target))

    return analysistest.end(env)

selected_foreign_test = analysistest.make(
    _selected_foreign_impl,
    attrs = {
        "expected_dynamic": attr.string(mandatory = True),
        "expected_runfiles": attr.string_list(mandatory = True),
        "expected_static": attr.string(mandatory = True),
    },
)
matches_cc_import_test = analysistest.make(
    _matches_cc_import_impl,
    attrs = {
        "control": attr.label(
            mandatory = True,
            providers = [CcInfo],
        ),
    },
)

def foreign_cc_multi_library_expect_failure_test(*, name, target, failure_message):
    expect_failure_test(
        name = name,
        target = target,
        failure_message = failure_message,
    )
