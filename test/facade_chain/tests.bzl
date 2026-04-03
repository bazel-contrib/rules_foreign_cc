"""Analysis tests for the 3-level facade chain matrix."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_cc//cc:defs.bzl", "CcInfo")
load("//test:facade_test_utils.bzl", "cc_defines", "cc_library_summary", "cc_linkopts", "default_files_basenames", "default_runfiles_basenames", "system_includes")

def _foreign_chain_matches_native_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    control = ctx.attr.control

    asserts.equals(env, default_files_basenames(control), default_files_basenames(target))
    asserts.equals(env, cc_library_summary(control, include_alwayslink = True), cc_library_summary(target, include_alwayslink = True))
    asserts.equals(env, cc_linkopts(control), cc_linkopts(target))
    asserts.equals(env, default_runfiles_basenames(control), default_runfiles_basenames(target))
    asserts.equals(env, cc_defines(control), cc_defines(target))
    asserts.equals(env, system_includes(control), system_includes(target))

    return analysistest.end(env)

foreign_chain_matches_native_test = analysistest.make(
    _foreign_chain_matches_native_impl,
    attrs = {
        "control": attr.label(
            mandatory = True,
            providers = [CcInfo],
        ),
    },
)
