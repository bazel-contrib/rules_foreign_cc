"""Analysis tests for the initial foreign_cc binary facade fixture."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

def _runfiles_basenames(target):
    basenames = {}
    for file in target[DefaultInfo].default_runfiles.files.to_list():
        if file.is_directory:
            continue
        basenames[file.basename] = True
    return sorted(basenames.keys())

def _assert_contains_all(env, actual, expected):
    actual_set = {}
    for item in actual:
        actual_set[item] = True

    missing = []
    for item in expected:
        if item not in actual_set:
            missing.append(item)

    asserts.equals(env, [], missing)

def _foreign_cc_binary_explicit_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    asserts.equals(env, [ctx.attr.expected_executable], [file.basename for file in target[DefaultInfo].files.to_list()])
    asserts.equals(env, ctx.attr.expected_executable, target[DefaultInfo].files_to_run.executable.basename)
    _assert_contains_all(
        env,
        _runfiles_basenames(target),
        ctx.attr.expected_runfiles,
    )
    asserts.equals(env, ctx.attr.expected_binary, target[DefaultInfo].default_runfiles.root_symlinks.to_list()[0].target_file.basename)

    return analysistest.end(env)

def _foreign_cc_binary_default_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    asserts.equals(env, ctx.attr.expected_executable, target[DefaultInfo].files_to_run.executable.basename)
    _assert_contains_all(
        env,
        _runfiles_basenames(target),
        ctx.attr.expected_runfiles,
    )
    asserts.equals(env, ctx.attr.expected_binary, target[DefaultInfo].default_runfiles.root_symlinks.to_list()[0].target_file.basename)

    return analysistest.end(env)

foreign_cc_binary_explicit_test = analysistest.make(
    _foreign_cc_binary_explicit_impl,
    attrs = {
        "expected_binary": attr.string(mandatory = True),
        "expected_executable": attr.string(mandatory = True),
        "expected_runfiles": attr.string_list(mandatory = True),
    },
)
foreign_cc_binary_default_test = analysistest.make(
    _foreign_cc_binary_default_impl,
    attrs = {
        "expected_binary": attr.string(mandatory = True),
        "expected_executable": attr.string(mandatory = True),
        "expected_runfiles": attr.string_list(mandatory = True),
    },
)
