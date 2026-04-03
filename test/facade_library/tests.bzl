"""Analysis tests for the initial foreign_cc library and import fixtures."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_cc//cc:defs.bzl", "CcInfo")

def _library_files(target):
    linker_inputs = target[CcInfo].linking_context.linker_inputs.to_list()
    libraries = []
    for linker_input in linker_inputs:
        for library in linker_input.libraries:
            libraries.append(struct(
                dynamic = library.dynamic_library.basename if library.dynamic_library else "",
                interface = library.interface_library.basename if library.interface_library else "",
                static = library.static_library.basename if library.static_library else (
                    library.pic_static_library.basename if library.pic_static_library else ""
                ),
            ))
    return libraries

def _default_runfiles_basenames(target):
    basenames = {}
    for file in target[DefaultInfo].default_runfiles.files.to_list():
        if file.is_directory:
            continue
        basenames[file.basename] = True
    return sorted(basenames.keys())

def _default_files_basenames(target):
    return sorted([file.basename for file in target[DefaultInfo].files.to_list()])

def _library_summary(target):
    libraries = _library_files(target)
    return sorted([
        "{}|{}|{}".format(lib.dynamic, lib.interface, lib.static)
        for lib in libraries
    ])

def _foreign_cc_library_explicit_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    libs = _library_files(target)

    asserts.equals(env, sorted(ctx.attr.expected_default_files), _default_files_basenames(target))
    asserts.equals(env, 1, len(libs))
    asserts.equals(env, ctx.attr.expected_dynamic, libs[0].dynamic)
    asserts.equals(env, ctx.attr.expected_static, libs[0].static)
    asserts.equals(
        env,
        sorted(ctx.attr.expected_runfiles),
        _default_runfiles_basenames(target),
    )

    return analysistest.end(env)

def _foreign_cc_library_inferred_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    libs = _library_files(target)

    asserts.equals(env, 1, len(libs))
    asserts.equals(env, ctx.attr.expected_dynamic, libs[0].dynamic)
    asserts.equals(env, ctx.attr.expected_static, libs[0].static)

    return analysistest.end(env)

def _foreign_cc_import_explicit_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    libs = _library_files(target)

    asserts.equals(env, sorted(ctx.attr.expected_default_files), _default_files_basenames(target))
    asserts.equals(env, 1, len(libs))
    asserts.equals(env, ctx.attr.expected_dynamic, libs[0].dynamic)
    asserts.equals(env, ctx.attr.expected_static, libs[0].static)
    asserts.equals(
        env,
        sorted(ctx.attr.expected_runfiles),
        _default_runfiles_basenames(target),
    )

    return analysistest.end(env)

def _foreign_cc_import_matches_cc_import_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    control = ctx.attr.control

    asserts.equals(env, _library_summary(control), _library_summary(target))

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
foreign_cc_library_inferred_test = analysistest.make(
    _foreign_cc_library_inferred_impl,
    attrs = {
        "expected_dynamic": attr.string(mandatory = True),
        "expected_static": attr.string(mandatory = True),
    },
)
