"""Facade rules that project raw foreign_cc producer targets into cc_*-like shapes."""

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load("@rules_cc//cc:defs.bzl", "CcInfo", "cc_common")
load("//foreign_cc:providers.bzl", "ForeignCcFacadeInputsInfo")
load("//foreign_cc/private:cc_toolchain_util.bzl", "LibrariesToLinkInfo", "create_linking_info")
load("//foreign_cc/private:framework.bzl", "CC_EXTERNAL_RULE_FRAGMENTS")

def _file_by_basename(files, basename):
    for file in files:
        if file.basename == basename:
            return file
    return None

def _is_numeric_suffix(segment):
    if not segment:
        return False
    for i in range(len(segment)):
        char = segment[i]
        if char < "0" or char > "9":
            return False
    return True

def _strip_trailing_numeric_segments(name):
    parts = name.split(".")
    end = len(parts)
    for i in range(len(parts) - 1, 0, -1):
        if not _is_numeric_suffix(parts[i]):
            break
        end = i
    return ".".join(parts[:end])

def _shared_stem(file_name):
    if ".so" in file_name:
        return file_name[:file_name.find(".so")]
    if ".dylib" in file_name:
        return _strip_trailing_numeric_segments(file_name[:file_name.find(".dylib")])
    if file_name.endswith(".dll"):
        return file_name.removesuffix(".dll")
    return file_name

def _static_stem(file_name):
    if file_name.endswith(".pic.a"):
        return file_name.removesuffix(".pic.a")
    if file_name.endswith(".a"):
        return file_name.removesuffix(".a")
    if file_name.endswith(".lib"):
        return file_name.removesuffix(".lib")
    return file_name

def _interface_stem(file_name):
    if file_name.endswith(".ifso"):
        return file_name.removesuffix(".ifso")
    if file_name.endswith(".tbd"):
        return file_name.removesuffix(".tbd")
    if file_name.endswith(".dll.a"):
        return file_name.removesuffix(".dll.a")
    if file_name.endswith(".lib"):
        return file_name.removesuffix(".lib")
    if file_name.endswith(".so"):
        return file_name.removesuffix(".so")
    if file_name.endswith(".dylib"):
        return file_name.removesuffix(".dylib")
    return file_name

def _single_stem_or_none(files, stem_fn):
    stems = {}
    for file in files:
        stems[stem_fn(file.basename)] = True
    if len(stems) == 1:
        return stems.keys()[0]
    return None

def _infer_shared_selection(shared_libraries):
    if not shared_libraries:
        return (None, [])

    stem = _single_stem_or_none(shared_libraries, _shared_stem)
    if stem == None:
        fail("Unable to infer a single shared-library family from `{}`. Please set `shared_library` explicitly.".format(
            ", ".join(sorted([file.basename for file in shared_libraries])),
        ))

    sorted_shared = sorted(shared_libraries, key = lambda file: (len(file.basename), file.basename))
    return (sorted_shared[0], sorted_shared)

def _infer_single_file(files, stem_fn, desc):
    if not files:
        return None

    stem = _single_stem_or_none(files, stem_fn)
    if stem == None or len(files) != 1:
        fail("Unable to infer a single {} from `{}`. Please set the matching facade attribute explicitly.".format(
            desc,
            ", ".join(sorted([file.basename for file in files])),
        ))
    return files[0]

def _infer_single_named_output(files, desc):
    if len(files) == 1:
        return files[0]
    fail("Unable to infer a single {} from `{}`. Please set the matching facade attribute explicitly.".format(
        desc,
        ", ".join(sorted([file.basename for file in files])),
    ))

def _select_library_outputs(ctx, facade_inputs):
    shared_libraries = facade_inputs.shared_libraries
    interface_libraries = facade_inputs.interface_libraries
    static_libraries = facade_inputs.static_libraries

    if ctx.attr.shared_library:
        selected_shared = _file_by_basename(shared_libraries, ctx.attr.shared_library)
        if selected_shared == None:
            fail("`shared_library` references `{}`, which is not a direct shared-library output of `{}`".format(
                ctx.attr.shared_library,
                ctx.attr.src.label,
            ))
        runtime_shared_files = [selected_shared]
    else:
        selected_shared, runtime_shared_files = _infer_shared_selection(shared_libraries)

    runtime_shared = None
    if ctx.attr.runtime_shared_library:
        runtime_shared = _file_by_basename(shared_libraries, ctx.attr.runtime_shared_library)
        if runtime_shared == None:
            fail("`runtime_shared_library` references `{}`, which is not a direct shared-library output of `{}`".format(
                ctx.attr.runtime_shared_library,
                ctx.attr.src.label,
            ))
        runtime_shared_files = [runtime_shared]

    for file_name in ctx.attr.additional_runtime_shared_libraries:
        file = _file_by_basename(shared_libraries, file_name)
        if file == None:
            fail("`additional_runtime_shared_libraries` references `{}`, which is not a direct shared-library output of `{}`".format(
                file_name,
                ctx.attr.src.label,
            ))
        if file not in runtime_shared_files:
            runtime_shared_files.append(file)

    if not runtime_shared_files and selected_shared:
        runtime_shared_files = [selected_shared]

    if ctx.attr.interface_library:
        interface_library = _file_by_basename(interface_libraries, ctx.attr.interface_library)
        if interface_library == None:
            fail("`interface_library` references `{}`, which is not a direct interface-library output of `{}`".format(
                ctx.attr.interface_library,
                ctx.attr.src.label,
            ))
    else:
        interface_library = _infer_single_file(interface_libraries, _interface_stem, "interface library") if interface_libraries else None

    if ctx.attr.static_library:
        static_library = _file_by_basename(static_libraries, ctx.attr.static_library)
        if static_library == None:
            fail("`static_library` references `{}`, which is not a direct static-library output of `{}`".format(
                ctx.attr.static_library,
                ctx.attr.src.label,
            ))
    else:
        static_library = _infer_single_file(static_libraries, _static_stem, "static library") if static_libraries else None

    if not selected_shared and not interface_library and not static_library:
        fail("`foreign_cc_library` could not select any direct library outputs from `{}`".format(ctx.attr.src.label))

    return struct(
        interface_library = interface_library,
        runtime_shared_files = runtime_shared_files,
        shared_library = selected_shared,
        static_library = static_library,
    )

def _create_compilation_context(ctx, include_dir):
    if include_dir == None:
        return cc_common.create_compilation_context(defines = depset(ctx.attr.defines))

    system_includes = [include_dir.path]
    for include in ctx.attr.includes:
        system_includes.append(include_dir.path + "/" + include)

    return cc_common.create_compilation_context(
        headers = depset([include_dir]),
        system_includes = depset(system_includes),
        defines = depset(ctx.attr.defines),
    )

def _create_default_info(ctx, selected, merged_runfiles):
    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    files = []
    if selected.static_library:
        files.append(selected.static_library)

    if selected.shared_library:
        files.append(selected.shared_library)

    if selected.interface_library and not cc_common.is_enabled(
        feature_configuration = feature_configuration,
        feature_name = "targets_windows",
    ):
        files.append(selected.interface_library)
    elif selected.interface_library and selected.shared_library == None:
        files.append(selected.interface_library)

    return DefaultInfo(
        files = depset(files),
        default_runfiles = merged_runfiles,
        data_runfiles = merged_runfiles,
    )

def _collect_transitive_shared_libraries(cc_info):
    shared_libraries = []
    for linker_input in cc_info.linking_context.linker_inputs.to_list():
        for lib in linker_input.libraries:
            if lib.dynamic_library:
                shared_libraries.append(lib.dynamic_library)
    return shared_libraries

def _foreign_cc_library_impl(ctx):
    facade_inputs = ctx.attr.src[ForeignCcFacadeInputsInfo]
    selected = _select_library_outputs(ctx, facade_inputs)

    compilation_context = _create_compilation_context(ctx, facade_inputs.include_dir)
    direct_linking_context = create_linking_info(
        ctx,
        ctx.attr.linkopts,
        LibrariesToLinkInfo(
            static_libraries = [selected.static_library] if selected.static_library else [],
            shared_libraries = [selected.shared_library] if selected.shared_library else [],
            interface_libraries = [selected.interface_library] if selected.interface_library else [],
        ),
    )
    direct_cc_info = CcInfo(
        compilation_context = compilation_context,
        linking_context = direct_linking_context,
    )
    merged_cc_info = cc_common.merge_cc_infos(cc_infos = [direct_cc_info, facade_inputs.deps_cc_info])

    runfiles = ctx.runfiles(
        files = selected.runtime_shared_files + _collect_transitive_shared_libraries(facade_inputs.deps_cc_info),
    )
    output_groups = {}
    if selected.static_library:
        output_groups["archive"] = depset([selected.static_library])
    if selected.shared_library or selected.interface_library:
        dynamic_outputs = []
        if selected.shared_library:
            dynamic_outputs.append(selected.shared_library)
        if selected.interface_library:
            dynamic_outputs.append(selected.interface_library)
        output_groups["dynamic_library"] = depset(dynamic_outputs)

    return [
        _create_default_info(ctx, selected, runfiles),
        merged_cc_info,
        OutputGroupInfo(**output_groups),
    ]

def _select_binary_outputs(ctx, facade_inputs):
    binary_files = facade_inputs.binary_files
    if not binary_files:
        fail("`foreign_cc_binary` could not find any direct binary outputs in `{}`".format(ctx.attr.src.label))

    if ctx.attr.binary:
        binary = _file_by_basename(binary_files, ctx.attr.binary)
        if binary == None:
            fail("`binary` references `{}`, which is not a direct binary output of `{}`".format(
                ctx.attr.binary,
                ctx.attr.src.label,
            ))
    else:
        binary = _infer_single_named_output(binary_files, "binary")

    runtime_shared_files = []
    if ctx.attr.runtime_shared_libraries:
        for file_name in ctx.attr.runtime_shared_libraries:
            file = _file_by_basename(facade_inputs.shared_libraries, file_name)
            if file == None:
                fail("`runtime_shared_libraries` references `{}`, which is not a direct shared-library output of `{}`".format(
                    file_name,
                    ctx.attr.src.label,
                ))
            runtime_shared_files.append(file)
    else:
        runtime_shared_files = facade_inputs.shared_libraries

    return struct(
        binary = binary,
        runtime_shared_files = runtime_shared_files,
    )

def _foreign_cc_binary_impl(ctx):
    facade_inputs = ctx.attr.src[ForeignCcFacadeInputsInfo]
    selected = _select_binary_outputs(ctx, facade_inputs)
    executable = ctx.actions.declare_file(ctx.label.name)

    # Give the launcher a deterministic runfiles location for the selected binary
    # instead of depending on producer-internal output layout.
    executable_runfile_path = "_foreign_cc_binary/{}/{}".format(
        ctx.label.name,
        selected.binary.basename,
    )
    ctx.actions.expand_template(
        template = ctx.file._runnable_wrapper_template,
        output = executable,
        substitutions = {
            "EXECUTABLE": executable_runfile_path,
        },
        is_executable = True,
    )

    runtime_shared_libraries = selected.runtime_shared_files + _collect_transitive_shared_libraries(facade_inputs.deps_cc_info)
    runfiles = ctx.runfiles(
        files = [executable, selected.binary] + runtime_shared_libraries,
        root_symlinks = {
            executable_runfile_path: selected.binary,
        },
    )
    runfiles = runfiles.merge(ctx.attr._runfiles_bash[DefaultInfo].default_runfiles)
    return [
        DefaultInfo(
            executable = executable,
            files = depset([executable]),
            default_runfiles = runfiles,
            data_runfiles = runfiles,
        ),
    ]

foreign_cc_library = rule(
    implementation = _foreign_cc_library_impl,
    attrs = {
        "additional_runtime_shared_libraries": attr.string_list(),
        "alwayslink": attr.bool(default = False),
        "defines": attr.string_list(),
        "includes": attr.string_list(),
        "interface_library": attr.string(default = ""),
        "linkopts": attr.string_list(),
        "runtime_shared_library": attr.string(default = ""),
        "shared_library": attr.string(default = ""),
        "src": attr.label(
            mandatory = True,
            providers = [ForeignCcFacadeInputsInfo],
        ),
        "static_library": attr.string(default = ""),
        "static_suffix": attr.string(default = ""),
        "_cc_toolchain": attr.label(
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        ),
    },
    doc = "Projects a raw foreign_cc producer target into a cc_library-like target.",
    fragments = CC_EXTERNAL_RULE_FRAGMENTS,
    provides = [CcInfo],
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
)

foreign_cc_import = rule(
    implementation = _foreign_cc_library_impl,
    attrs = {
        "additional_runtime_shared_libraries": attr.string_list(),
        "alwayslink": attr.bool(default = False),
        "defines": attr.string_list(),
        "includes": attr.string_list(),
        "interface_library": attr.string(default = ""),
        "linkopts": attr.string_list(),
        "runtime_shared_library": attr.string(default = ""),
        "shared_library": attr.string(default = ""),
        "src": attr.label(
            mandatory = True,
            providers = [ForeignCcFacadeInputsInfo],
        ),
        "static_library": attr.string(default = ""),
        "static_suffix": attr.string(default = ""),
        "_cc_toolchain": attr.label(
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        ),
    },
    doc = "Projects a raw foreign_cc producer target into a cc_import-like target.",
    fragments = CC_EXTERNAL_RULE_FRAGMENTS,
    provides = [CcInfo],
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
)

foreign_cc_binary = rule(
    implementation = _foreign_cc_binary_impl,
    attrs = {
        "binary": attr.string(default = ""),
        "runtime_shared_libraries": attr.string_list(),
        "src": attr.label(
            mandatory = True,
            providers = [ForeignCcFacadeInputsInfo],
        ),
        "_runfiles_bash": attr.label(
            default = Label("@bazel_tools//tools/bash/runfiles"),
        ),
        "_runnable_wrapper_template": attr.label(
            allow_single_file = True,
            default = Label("//foreign_cc/private:runnable_binary_wrapper.sh"),
        ),
    },
    doc = "Projects a raw foreign_cc producer target into a cc_binary-like target.",
    executable = True,
)
