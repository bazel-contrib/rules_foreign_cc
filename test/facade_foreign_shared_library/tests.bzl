"""Analysis tests for the Stage 1 foreign shared-library facade."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_cc//cc/common:cc_shared_library_hint_info.bzl", "CcSharedLibraryHintInfo")
load("@rules_cc//cc/common:cc_shared_library_info.bzl", "CcSharedLibraryInfo")
load("//test:facade_test_utils.bzl", "default_files_basenames", "default_runfiles_basenames", "expect_failure_test", "has_output_group", "output_group_basenames")

def _label_collection_values(values):
    if type(values) == "dict":
        return values.keys()
    return values

def _library_summary(library):
    return "dynamic={}|interface={}|static={}|pic_static={}".format(
        library.dynamic_library.basename if library.dynamic_library else "",
        library.interface_library.basename if library.interface_library else "",
        library.static_library.basename if library.static_library else "",
        library.pic_static_library.basename if library.pic_static_library else "",
    )

def _foreign_cc_shared_library_default_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    asserts.equals(env, ctx.attr.expected_default_files, default_files_basenames(target))
    asserts.equals(env, ctx.attr.expected_main_files, output_group_basenames(target, "main_shared_library_output"))
    asserts.equals(env, ctx.attr.expected_interface_files, output_group_basenames(target, "interface_library"))
    asserts.equals(env, sorted(ctx.attr.expected_runfiles), default_runfiles_basenames(target))
    asserts.equals(env, ctx.attr.expect_validation_output_group, has_output_group(target, "_validation"))
    asserts.false(env, has_output_group(target, "archive"))
    asserts.false(env, has_output_group(target, "dynamic_library"))

    return analysistest.end(env)

foreign_cc_shared_library_default_test = analysistest.make(
    _foreign_cc_shared_library_default_impl,
    attrs = {
        "expect_validation_output_group": attr.bool(mandatory = True),
        "expected_default_files": attr.string_list(mandatory = True),
        "expected_interface_files": attr.string_list(mandatory = True),
        "expected_main_files": attr.string_list(mandatory = True),
        "expected_runfiles": attr.string_list(mandatory = True),
    },
)

def _pretty_label(label):
    label_attr = getattr(label, "label", None)
    if label_attr != None:
        label = label_attr
    s = str(label)
    if s.startswith("<target ") and s.endswith(">"):
        s = s[len("<target "):-1]
    if s.startswith("@@//") or s.startswith("@//"):  # buildifier: disable=canonical-repository
        return s.lstrip("@")
    return s

def _foreign_cc_shared_library_hint_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    hint = target[CcSharedLibraryHintInfo]

    asserts.equals(env, sorted(ctx.attr.expected_attributes), sorted(getattr(hint, "attributes", [])))
    asserts.equals(
        env,
        sorted(ctx.attr.expected_owners),
        sorted([_pretty_label(owner) for owner in getattr(hint, "owners", [])]),
    )

    return analysistest.end(env)

foreign_cc_shared_library_hint_test = analysistest.make(
    _foreign_cc_shared_library_hint_impl,
    attrs = {
        "expected_attributes": attr.string_list(mandatory = True),
        "expected_owners": attr.string_list(mandatory = True),
    },
)

def _foreign_cc_shared_library_info_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    has_info = CcSharedLibraryInfo in target
    asserts.equals(env, ctx.attr.expect_info, has_info)
    if has_info:
        info = target[CcSharedLibraryInfo]
        asserts.equals(
            env,
            sorted(ctx.attr.expected_exports),
            sorted([_pretty_label(export) for export in info.exports]),
        )
        asserts.equals(env, ctx.attr.expected_dynamic_dep_count, len(info.dynamic_deps.to_list()))
        asserts.equals(
            env,
            sorted(ctx.attr.expected_dynamic_dep_owners),
            sorted([
                _pretty_label(entry.linker_input.owner)
                for entry in info.dynamic_deps.to_list()
            ]),
        )
        asserts.equals(
            env,
            ctx.attr.expected_link_once_static_lib_count,
            len(info.link_once_static_libs),
        )
        asserts.equals(
            env,
            sorted(ctx.attr.expected_link_once_static_libs),
            sorted([_pretty_label(label) for label in _label_collection_values(info.link_once_static_libs)]),
        )
        asserts.equals(
            env,
            sorted(ctx.attr.expected_linker_input_libraries),
            sorted([
                _library_summary(library)
                for library in info.linker_input.libraries
            ]),
        )

    return analysistest.end(env)

foreign_cc_shared_library_info_test = analysistest.make(
    _foreign_cc_shared_library_info_impl,
    attrs = {
        "expect_info": attr.bool(mandatory = True),
        "expected_dynamic_dep_count": attr.int(default = 0),
        "expected_dynamic_dep_owners": attr.string_list(),
        "expected_exports": attr.string_list(),
        "expected_link_once_static_lib_count": attr.int(default = 0),
        "expected_link_once_static_libs": attr.string_list(),
        "expected_linker_input_libraries": attr.string_list(),
    },
)

def foreign_cc_shared_library_expect_failure_test(*, name, target, failure_message):
    expect_failure_test(
        name = name,
        target = target,
        failure_message = failure_message,
    )
