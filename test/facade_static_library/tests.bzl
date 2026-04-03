"""Analysis tests for the foreign static-library facade."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//test:facade_test_utils.bzl", "default_files_basenames", "default_runfiles_basenames", "expect_failure_test", "has_output_group", "output_group_basenames")

def _foreign_cc_static_library_default_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    asserts.equals(env, ctx.attr.expected_default_files, default_files_basenames(target))
    asserts.equals(env, [ctx.attr.expected_linkdeps_file], output_group_basenames(target, "linkdeps"))
    asserts.equals(env, [ctx.attr.expected_linkopts_file], output_group_basenames(target, "linkopts"))
    asserts.equals(env, sorted(ctx.attr.expected_runfiles), default_runfiles_basenames(target))
    asserts.equals(env, ctx.attr.expect_validation_output_group, has_output_group(target, "_validation"))
    asserts.false(env, has_output_group(target, "archive"))
    asserts.false(env, has_output_group(target, "dynamic_library"))

    return analysistest.end(env)

foreign_cc_static_library_default_test = analysistest.make(
    _foreign_cc_static_library_default_impl,
    attrs = {
        "expect_validation_output_group": attr.bool(mandatory = True),
        "expected_default_files": attr.string_list(mandatory = True),
        "expected_linkdeps_file": attr.string(mandatory = True),
        "expected_linkopts_file": attr.string(mandatory = True),
        "expected_runfiles": attr.string_list(mandatory = True),
    },
)

def foreign_cc_static_library_expect_failure_test(*, name, target, failure_message):
    expect_failure_test(
        name = name,
        target = target,
        failure_message = failure_message,
    )
