"""Shared-library provider probes for native cc_shared_library behavior."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_cc//cc/common:cc_shared_library_info.bzl", "CcSharedLibraryInfo")

def _pretty_label(label):
    s = str(label)
    if s.startswith("@@//") or s.startswith("@//"):  # buildifier: disable=canonical-repository
        return s.lstrip("@")
    return s

def _library_summary(library):
    return "dynamic={}|interface={}|static={}|pic_static={}".format(
        library.dynamic_library.basename if library.dynamic_library else "",
        library.interface_library.basename if library.interface_library else "",
        library.static_library.basename if library.static_library else "",
        library.pic_static_library.basename if library.pic_static_library else "",
    )

def _basenames(files):
    return sorted([file.basename for file in files.to_list()])

def _label_collection_values(values):
    if type(values) == "dict":
        return values.keys()
    return values

def _shared_library_summary_impl(ctx):
    target = ctx.attr.target
    output = ctx.actions.declare_file(ctx.label.name + ".txt")
    shared_info = target[CcSharedLibraryInfo]

    lines = [
        "default_files={}".format(",".join(_basenames(target[DefaultInfo].files))),
        "main_shared_library_output={}".format(",".join(_basenames(getattr(target[OutputGroupInfo], "main_shared_library_output")))),
        "interface_library={}".format(",".join(_basenames(getattr(target[OutputGroupInfo], "interface_library")))),
        "exports={}".format(",".join(sorted([_pretty_label(label) for label in shared_info.exports]))),
        "dynamic_deps={}".format(",".join(sorted([
            _pretty_label(entry.linker_input.owner)
            for entry in shared_info.dynamic_deps.to_list()
        ]))),
        "link_once_static_libs={}".format(",".join(sorted([
            _pretty_label(label)
            for label in _label_collection_values(shared_info.link_once_static_libs)
        ]))),
        "linker_input={}".format(",".join(sorted([
            _library_summary(library)
            for library in shared_info.linker_input.libraries
        ]))),
    ]

    ctx.actions.write(output = output, content = "\n".join(lines) + "\n")
    return [DefaultInfo(files = depset([output]))]

shared_library_summary = rule(
    implementation = _shared_library_summary_impl,
    attrs = {
        "target": attr.label(
            mandatory = True,
            providers = [CcSharedLibraryInfo],
        ),
    },
)

def _runfiles_basenames(target):
    basenames = {}
    for file in target[DefaultInfo].default_runfiles.files.to_list():
        if file.is_directory:
            continue
        basenames[file.basename] = True
    return sorted(basenames.keys())

def _runfiles_presence_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    runfiles = _runfiles_basenames(target)

    for basename in ctx.attr.required_basenames:
        asserts.true(env, basename in runfiles, "expected `{}` in {}".format(basename, runfiles))
    for basename in ctx.attr.forbidden_basenames:
        asserts.false(env, basename in runfiles, "did not expect `{}` in {}".format(basename, runfiles))

    return analysistest.end(env)

runfiles_presence_test = analysistest.make(
    _runfiles_presence_impl,
    attrs = {
        "forbidden_basenames": attr.string_list(),
        "required_basenames": attr.string_list(),
    },
)

def _runfiles_summary_impl(ctx):
    target = ctx.attr.target
    output = ctx.actions.declare_file(ctx.label.name + ".txt")
    ctx.actions.write(output = output, content = "\n".join(_runfiles_basenames(target)) + "\n")
    return [DefaultInfo(files = depset([output]))]

runfiles_summary = rule(
    implementation = _runfiles_summary_impl,
    attrs = {
        "target": attr.label(mandatory = True),
    },
)

def _shared_library_output_summary_impl(ctx):
    target = ctx.attr.target
    output = ctx.actions.declare_file(ctx.label.name + ".txt")
    lines = [
        "default_files={}".format(",".join(_basenames(target[DefaultInfo].files))),
        "main_shared_library_output={}".format(",".join(_basenames(getattr(target[OutputGroupInfo], "main_shared_library_output")))),
        "interface_library={}".format(",".join(_basenames(getattr(target[OutputGroupInfo], "interface_library")))),
    ]
    ctx.actions.write(output = output, content = "\n".join(lines) + "\n")
    return [DefaultInfo(files = depset([output]))]

shared_library_output_summary = rule(
    implementation = _shared_library_output_summary_impl,
    attrs = {
        "target": attr.label(mandatory = True),
    },
)

def _file_kind(file):
    name = file.basename
    if name.endswith(".if.lib") or name.endswith(".lib") or name.endswith(".ifso") or name.endswith(".tbd"):
        return "interface"
    if name.endswith(".dll") or name.endswith(".so") or name.endswith(".dylib"):
        return "shared"
    return "other"

def _file_kinds(files):
    return ",".join(sorted([_file_kind(file) for file in files.to_list()]))

def _shared_library_shape_summary_impl(ctx):
    target = ctx.attr.target
    output = ctx.actions.declare_file(ctx.label.name + ".txt")
    shared_info = target[CcSharedLibraryInfo]
    libraries = list(shared_info.linker_input.libraries)

    lines = [
        "default_file_kinds={}".format(_file_kinds(target[DefaultInfo].files)),
        "main_output_kinds={}".format(_file_kinds(getattr(target[OutputGroupInfo], "main_shared_library_output"))),
        "interface_output_kinds={}".format(_file_kinds(getattr(target[OutputGroupInfo], "interface_library"))),
        "exports_count={}".format(len(shared_info.exports)),
        "dynamic_dep_count={}".format(len(shared_info.dynamic_deps.to_list())),
        "link_once_static_lib_count={}".format(len(_label_collection_values(shared_info.link_once_static_libs))),
        "linker_input_library_count={}".format(len(libraries)),
        "linker_input_has_dynamic={}".format(any([lib.dynamic_library != None for lib in libraries])),
        "linker_input_has_interface={}".format(any([lib.interface_library != None for lib in libraries])),
        "linker_input_has_static={}".format(any([lib.static_library != None or lib.pic_static_library != None for lib in libraries])),
    ]

    ctx.actions.write(output = output, content = "\n".join(lines) + "\n")
    return [DefaultInfo(files = depset([output]))]

shared_library_shape_summary = rule(
    implementation = _shared_library_shape_summary_impl,
    attrs = {
        "target": attr.label(
            mandatory = True,
            providers = [CcSharedLibraryInfo],
        ),
    },
)
