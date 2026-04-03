"""Analysis tests for the Stage 1 foreign shared-library facade."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

def _default_files_basenames(target):
    return sorted([file.basename for file in target[DefaultInfo].files.to_list()])

def _output_group_basenames(target, name):
    return sorted([file.basename for file in getattr(target[OutputGroupInfo], name).to_list()])

def _runfiles_basenames(target):
    basenames = {}
    for file in target[DefaultInfo].default_runfiles.files.to_list():
        if file.is_directory:
            continue
        basenames[file.basename] = True
    return sorted(basenames.keys())

def _foreign_cc_shared_library_default_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    asserts.equals(env, ctx.attr.expected_default_files, _default_files_basenames(target))
    asserts.equals(env, ctx.attr.expected_main_files, _output_group_basenames(target, "main_shared_library_output"))
    asserts.equals(env, ctx.attr.expected_interface_files, _output_group_basenames(target, "interface_library"))
    asserts.equals(env, sorted(ctx.attr.expected_runfiles), _runfiles_basenames(target))

    return analysistest.end(env)

foreign_cc_shared_library_default_test = analysistest.make(
    _foreign_cc_shared_library_default_impl,
    attrs = {
        "expected_default_files": attr.string_list(mandatory = True),
        "expected_interface_files": attr.string_list(mandatory = True),
        "expected_main_files": attr.string_list(mandatory = True),
        "expected_runfiles": attr.string_list(mandatory = True),
    },
)
