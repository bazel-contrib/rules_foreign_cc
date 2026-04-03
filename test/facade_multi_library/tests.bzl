"""Analysis tests for explicit multi-library foreign_cc facade selection."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_cc//cc:defs.bzl", "CcInfo")

def _selected_library(target):
    linker_inputs = target[CcInfo].linking_context.linker_inputs.to_list()
    for linker_input in linker_inputs:
        if linker_input.libraries:
            library = linker_input.libraries[0]
            return struct(
                dynamic = library.dynamic_library.basename if library.dynamic_library else "",
                static = library.static_library.basename if library.static_library else (
                    library.pic_static_library.basename if library.pic_static_library else ""
                ),
            )
    fail("Expected at least one library in linking context")

def _unique_runfiles(target):
    basenames = {}
    for file in target[DefaultInfo].default_runfiles.files.to_list():
        if file.is_directory:
            continue
        basenames[file.basename] = True
    return sorted(basenames.keys())

def _library_summary(target):
    linker_inputs = target[CcInfo].linking_context.linker_inputs.to_list()
    libraries = []
    for linker_input in linker_inputs:
        for library in linker_input.libraries:
            libraries.append("{}|{}|{}".format(
                library.dynamic_library.basename if library.dynamic_library else "",
                library.interface_library.basename if library.interface_library else "",
                library.static_library.basename if library.static_library else (
                    library.pic_static_library.basename if library.pic_static_library else ""
                ),
            ))
    return sorted(libraries)

def _first_foreign_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    library = _selected_library(target)

    asserts.equals(env, ctx.attr.expected_dynamic, library.dynamic)
    asserts.equals(env, ctx.attr.expected_static, library.static)
    asserts.equals(env, sorted(ctx.attr.expected_runfiles), _unique_runfiles(target))

    return analysistest.end(env)

def _second_foreign_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    library = _selected_library(target)

    asserts.equals(env, ctx.attr.expected_dynamic, library.dynamic)
    asserts.equals(env, ctx.attr.expected_static, library.static)
    asserts.equals(env, sorted(ctx.attr.expected_runfiles), _unique_runfiles(target))

    return analysistest.end(env)

def _matches_cc_import_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    control = ctx.attr.control

    asserts.equals(env, _library_summary(control), _library_summary(target))

    return analysistest.end(env)

first_foreign_test = analysistest.make(
    _first_foreign_impl,
    attrs = {
        "expected_dynamic": attr.string(mandatory = True),
        "expected_runfiles": attr.string_list(mandatory = True),
        "expected_static": attr.string(mandatory = True),
    },
)
first_matches_cc_import_test = analysistest.make(
    _matches_cc_import_impl,
    attrs = {
        "control": attr.label(
            mandatory = True,
            providers = [CcInfo],
        ),
    },
)
second_foreign_test = analysistest.make(
    _second_foreign_impl,
    attrs = {
        "expected_dynamic": attr.string(mandatory = True),
        "expected_runfiles": attr.string_list(mandatory = True),
        "expected_static": attr.string(mandatory = True),
    },
)
second_matches_cc_import_test = analysistest.make(
    _matches_cc_import_impl,
    attrs = {
        "control": attr.label(
            mandatory = True,
            providers = [CcInfo],
        ),
    },
)
