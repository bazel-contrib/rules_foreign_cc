"""Analysis tests for the 3-level facade chain matrix."""

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

def _library_summary(target):
    libraries = _library_files(target)
    return sorted([
        "{}|{}|{}".format(lib.dynamic, lib.interface, lib.static)
        for lib in libraries
    ])

def _foreign_chain_matches_native_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    control = ctx.attr.control

    asserts.equals(env, _library_summary(control), _library_summary(target))

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
