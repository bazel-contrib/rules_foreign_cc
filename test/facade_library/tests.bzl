"""Analysis tests for the initial foreign_cc library and import fixtures."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_cc//cc:defs.bzl", "CcInfo")
load("//test:facade_test_utils.bzl", "cc_defines", "cc_library_summary", "cc_library_to_link_structs", "cc_linkopts", "default_files_basenames", "default_runfiles_basenames", "expect_failure_test", "has_output_group", "system_includes")

def _assert_library_selection(env, target, *, expected_default_files = None, expected_dynamic, expected_runfiles = None, expected_static):
    libs = cc_library_to_link_structs(target)

    if expected_default_files != None:
        asserts.equals(env, sorted(expected_default_files), default_files_basenames(target))
    asserts.equals(env, 1, len(libs))
    asserts.equals(env, expected_dynamic, libs[0].dynamic)
    asserts.equals(env, expected_static, libs[0].static)
    if expected_runfiles != None:
        asserts.equals(env, sorted(expected_runfiles), default_runfiles_basenames(target))
        asserts.false(env, has_output_group(target, "archive"))
        asserts.false(env, has_output_group(target, "dynamic_library"))

def _foreign_cc_library_explicit_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    _assert_library_selection(
        env,
        target,
        expected_default_files = ctx.attr.expected_default_files,
        expected_dynamic = ctx.attr.expected_dynamic,
        expected_runfiles = ctx.attr.expected_runfiles,
        expected_static = ctx.attr.expected_static,
    )

    return analysistest.end(env)

def _foreign_cc_library_inferred_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    _assert_library_selection(
        env,
        target,
        expected_dynamic = ctx.attr.expected_dynamic,
        expected_static = ctx.attr.expected_static,
    )

    return analysistest.end(env)

def _foreign_cc_import_explicit_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    _assert_library_selection(
        env,
        target,
        expected_default_files = ctx.attr.expected_default_files,
        expected_dynamic = ctx.attr.expected_dynamic,
        expected_runfiles = ctx.attr.expected_runfiles,
        expected_static = ctx.attr.expected_static,
    )

    return analysistest.end(env)

def _foreign_cc_import_matches_cc_import_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    control = ctx.attr.control

    asserts.equals(env, default_files_basenames(control), default_files_basenames(target))
    asserts.equals(env, cc_library_summary(control, include_alwayslink = True, include_pic_static = True), cc_library_summary(target, include_alwayslink = True, include_pic_static = True))
    asserts.equals(env, cc_linkopts(control), cc_linkopts(target))
    asserts.equals(env, cc_defines(control), cc_defines(target))
    asserts.equals(env, default_runfiles_basenames(control), default_runfiles_basenames(target))

    return analysistest.end(env)

def _foreign_cc_includes_match_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    control = ctx.attr.control

    asserts.equals(env, system_includes(control), system_includes(target))

    return analysistest.end(env)

foreign_cc_library_explicit_test = analysistest.make(
    _foreign_cc_library_explicit_impl,
    attrs = {
        "expected_default_files": attr.string_list(mandatory = True),
        "expected_dynamic": attr.string(mandatory = True),
        "expected_runfiles": attr.string_list(mandatory = True),
        "expected_static": attr.string(mandatory = True),
    },
)
foreign_cc_import_explicit_test = analysistest.make(
    _foreign_cc_import_explicit_impl,
    attrs = {
        "expected_default_files": attr.string_list(mandatory = True),
        "expected_dynamic": attr.string(mandatory = True),
        "expected_runfiles": attr.string_list(mandatory = True),
        "expected_static": attr.string(mandatory = True),
    },
)
foreign_cc_import_matches_cc_import_test = analysistest.make(
    _foreign_cc_import_matches_cc_import_impl,
    attrs = {
        "control": attr.label(
            mandatory = True,
            providers = [CcInfo],
        ),
    },
)
foreign_cc_includes_match_test = analysistest.make(
    _foreign_cc_includes_match_impl,
    attrs = {
        "control": attr.label(
            mandatory = True,
            providers = [CcInfo],
        ),
    },
)
foreign_cc_library_inferred_test = analysistest.make(
    _foreign_cc_library_inferred_impl,
    attrs = {
        "expected_dynamic": attr.string(mandatory = True),
        "expected_static": attr.string(mandatory = True),
    },
)

def foreign_cc_library_expect_failure_test(*, name, target, failure_message):
    expect_failure_test(
        name = name,
        target = target,
        failure_message = failure_message,
    )
