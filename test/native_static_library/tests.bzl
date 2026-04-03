"""Analysis tests for native cc_static_library behavior."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

def _default_files_basenames(target):
    return sorted([file.basename for file in target[DefaultInfo].files.to_list()])

def _output_group_basenames(target, name):
    return sorted([file.basename for file in getattr(target[OutputGroupInfo], name).to_list()])

def _native_cc_static_library_default_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    asserts.equals(env, ctx.attr.expected_default_files, _default_files_basenames(target))
    asserts.equals(env, [ctx.attr.expected_linkdeps_file], _output_group_basenames(target, "linkdeps"))
    asserts.equals(env, [ctx.attr.expected_linkopts_file], _output_group_basenames(target, "linkopts"))

    return analysistest.end(env)

native_cc_static_library_default_test = analysistest.make(
    _native_cc_static_library_default_impl,
    attrs = {
        "expected_default_files": attr.string_list(mandatory = True),
        "expected_linkdeps_file": attr.string(mandatory = True),
        "expected_linkopts_file": attr.string(mandatory = True),
    },
)
