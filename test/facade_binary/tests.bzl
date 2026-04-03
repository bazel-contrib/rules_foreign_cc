"""Analysis tests for the initial foreign_cc binary facade fixture."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//test:facade_test_utils.bzl", "assert_contains_all", "default_runfiles_basenames", "expect_failure_test")

def _foreign_cc_binary_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    asserts.equals(env, [ctx.attr.expected_executable], [file.basename for file in target[DefaultInfo].files.to_list()])
    asserts.equals(env, ctx.attr.expected_executable, target[DefaultInfo].files_to_run.executable.basename)
    assert_contains_all(
        env,
        default_runfiles_basenames(target),
        ctx.attr.expected_runfiles,
    )
    asserts.equals(env, ctx.attr.expected_binary, target[DefaultInfo].default_runfiles.root_symlinks.to_list()[0].target_file.basename)

    return analysistest.end(env)

foreign_cc_binary_explicit_test = analysistest.make(
    _foreign_cc_binary_impl,
    attrs = {
        "expected_binary": attr.string(mandatory = True),
        "expected_executable": attr.string(mandatory = True),
        "expected_runfiles": attr.string_list(mandatory = True),
    },
)
foreign_cc_binary_default_test = analysistest.make(
    _foreign_cc_binary_impl,
    attrs = {
        "expected_binary": attr.string(mandatory = True),
        "expected_executable": attr.string(mandatory = True),
        "expected_runfiles": attr.string_list(mandatory = True),
    },
)

def foreign_cc_binary_expect_failure_test(*, name, target, failure_message):
    expect_failure_test(
        name = name,
        target = target,
        failure_message = failure_message,
    )
