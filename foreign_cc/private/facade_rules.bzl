"""Facade rules that project raw foreign_cc producer targets into cc_*-like shapes."""

load("@bazel_features//:features.bzl", "bazel_features")
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:defs.bzl", "CcInfo", "cc_common")
load("@rules_cc//cc/common:cc_shared_library_hint_info.bzl", "CcSharedLibraryHintInfo")
load("//foreign_cc:providers.bzl", "ForeignCcFacadeInputsInfo")
load("//foreign_cc/private:framework.bzl", "CC_EXTERNAL_RULE_FRAGMENTS")

CcSharedLibraryInfo = bazel_features.globals.CcSharedLibraryInfo

def _file_by_basename(files, basename):
    for file in files:
        if file.basename == basename:
            return file
    return None

def _normalize_header_prefix(prefix):
    if not prefix:
        return ""
    parts = []
    for segment in prefix.replace("\\", "/").split("/"):
        if not segment or segment == ".":
            continue
        parts.append(segment)
    return "/".join(parts)

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
    if file_name.endswith(".pic.lib"):
        return file_name.removesuffix(".pic.lib")
    if file_name.endswith(".pic.a"):
        return file_name.removesuffix(".pic.a")
    if file_name.endswith(".a"):
        return file_name.removesuffix(".a")
    if file_name.endswith(".lib"):
        return file_name.removesuffix(".lib")
    return file_name

def _is_pic_static_library_name(file_name):
    return file_name.endswith(".pic.a") or file_name.endswith(".pic.lib")

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

def _infer_static_selection(static_libraries):
    if not static_libraries:
        return (None, None)

    stem = _single_stem_or_none(static_libraries, _static_stem)
    if stem == None:
        fail("Unable to infer a single static library from `{}`. Please set the matching facade attribute explicitly.".format(
            ", ".join(sorted([file.basename for file in static_libraries])),
        ))

    static_library = None
    pic_static_library = None
    for file in static_libraries:
        if _is_pic_static_library_name(file.basename):
            if pic_static_library != None:
                fail("Unable to infer a single static library from `{}`. Please set the matching facade attribute explicitly.".format(
                    ", ".join(sorted([candidate.basename for candidate in static_libraries])),
                ))
            pic_static_library = file
        else:
            if static_library != None:
                fail("Unable to infer a single static library from `{}`. Please set the matching facade attribute explicitly.".format(
                    ", ".join(sorted([candidate.basename for candidate in static_libraries])),
                ))
            static_library = file

    return (static_library, pic_static_library)

def _matching_static_family_files(files, stem, static_suffix):
    if stem == None:
        return files

    matched = []
    suffixed_stem = stem + static_suffix if static_suffix else None
    for file in files:
        file_stem = _static_stem(file.basename)
        if file_stem == stem or (suffixed_stem != None and file_stem == suffixed_stem):
            matched.append(file)
    return matched

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
    interface_library_name = getattr(ctx.attr, "interface_library", "")
    pic_static_library_name = getattr(ctx.attr, "pic_static_library", "")
    static_library_name = getattr(ctx.attr, "static_library", "")
    system_provided = getattr(ctx.attr, "system_provided", False)

    if system_provided and not ctx.attr.shared_library:
        selected_shared = None
        runtime_shared_files = []
    elif ctx.attr.shared_library:
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

    if interface_library_name:
        interface_library = _file_by_basename(interface_libraries, interface_library_name)
        if interface_library == None:
            interface_library = _file_by_basename(shared_libraries, interface_library_name)
        if interface_library == None:
            fail("`interface_library` references `{}`, which is not a direct interface-library output of `{}`".format(
                interface_library_name,
                ctx.attr.src.label,
            ))
    else:
        interface_library = _infer_single_file(interface_libraries, _interface_stem, "interface library") if interface_libraries else None

    selected_static_stem = None
    if selected_shared != None:
        selected_static_stem = _shared_stem(selected_shared.basename)
    elif interface_library != None:
        selected_static_stem = _interface_stem(interface_library.basename)

    candidate_static_libraries = _matching_static_family_files(
        static_libraries,
        selected_static_stem,
        getattr(ctx.attr, "static_suffix", ""),
    )
    static_library, pic_static_library = _infer_static_selection(candidate_static_libraries)

    if static_library_name:
        static_library = _file_by_basename(static_libraries, static_library_name)
        if static_library == None:
            fail("`static_library` references `{}`, which is not a direct static-library output of `{}`".format(
                static_library_name,
                ctx.attr.src.label,
            ))
    if pic_static_library_name:
        pic_static_library = _file_by_basename(static_libraries, pic_static_library_name)
        if pic_static_library == None:
            fail("`pic_static_library` references `{}`, which is not a direct static-library output of `{}`".format(
                pic_static_library_name,
                ctx.attr.src.label,
            ))

    if not selected_shared and not interface_library and not static_library and not pic_static_library:
        fail("`foreign_cc_library` could not select any direct library outputs from `{}`".format(ctx.attr.src.label))

    return struct(
        interface_library = interface_library,
        pic_static_library = pic_static_library,
        runtime_shared_files = runtime_shared_files,
        shared_library = selected_shared,
        static_library = static_library,
    )

def _create_remapped_include_dir(ctx, include_dir, header_manifest):
    include_prefix = _normalize_header_prefix(getattr(ctx.attr, "include_prefix", ""))
    strip_include_prefix = _normalize_header_prefix(getattr(ctx.attr, "strip_include_prefix", ""))
    if include_dir == None or (not include_prefix and not strip_include_prefix):
        return include_dir

    remapped_include_dir = ctx.actions.declare_directory(ctx.label.name + ".virtual_includes")
    ctx.actions.run_shell(
        mnemonic = "ForeignCcRemapHeaders",
        inputs = depset([include_dir, header_manifest]),
        outputs = [remapped_include_dir],
        command = """
set -eu
header_root="{header_root}"
header_manifest="{header_manifest}"
include_prefix="{include_prefix}"
strip_include_prefix="{strip_include_prefix}"
out_dir="{out_dir}"
mkdir -p "$out_dir"
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  mapped="$rel"
  if [ -n "$strip_include_prefix" ]; then
    case "$mapped" in
      "$strip_include_prefix"/*)
        mapped="${{mapped#"$strip_include_prefix"/}}"
        ;;
      *)
        continue
        ;;
    esac
  fi
  if [ -n "$include_prefix" ]; then
    mapped="$include_prefix/$mapped"
  fi
  dest="$out_dir/$mapped"
  mkdir -p "$(dirname "$dest")"
  cp -f "$header_root/$rel" "$dest"
done < "$header_manifest"
""".format(
            header_manifest = header_manifest.path,
            header_root = include_dir.path,
            include_prefix = include_prefix,
            out_dir = remapped_include_dir.path,
            strip_include_prefix = strip_include_prefix,
        ),
        progress_message = "Foreign Cc - remapping headers for {}".format(ctx.label),
    )
    return remapped_include_dir

def _create_compilation_context(ctx, include_dir, header_manifest):
    if include_dir == None:
        return cc_common.create_compilation_context(defines = depset(ctx.attr.defines))

    include_dir = _create_remapped_include_dir(ctx, include_dir, header_manifest)
    system_includes = [include_dir.path]
    for include in ctx.attr.includes:
        system_includes.append(include_dir.path + "/" + include)

    return cc_common.create_compilation_context(
        headers = depset([include_dir]),
        system_includes = depset(system_includes),
        defines = depset(ctx.attr.defines),
    )

def _create_default_info(merged_runfiles, data_runfiles = None):
    # Native cc_library / cc_import targets expose linkable artifacts via CcInfo rather than
    # target.files. Keep the facade's direct outputs on OutputGroupInfo and leave DefaultInfo empty.
    if data_runfiles == None:
        data_runfiles = merged_runfiles
    return DefaultInfo(
        files = depset(),
        default_runfiles = merged_runfiles,
        data_runfiles = data_runfiles,
    )

def _merge_data_runfiles(ctx, runfiles, data_deps):
    for data_dep in data_deps:
        if DefaultInfo not in data_dep:
            continue
        if data_dep[DefaultInfo].data_runfiles.files:
            runfiles = runfiles.merge(data_dep[DefaultInfo].data_runfiles)
        else:
            # Match native cc_library's interop path for custom Starlark rules
            # that expose files and default_runfiles but not data_runfiles.
            runfiles = runfiles.merge(ctx.runfiles(transitive_files = data_dep[DefaultInfo].files))
            runfiles = runfiles.merge(data_dep[DefaultInfo].default_runfiles)
    return runfiles

def _create_selected_linking_context(ctx, selected):
    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    if (
        selected.pic_static_library == None and
        selected.static_library == None and
        selected.shared_library == None and
        selected.interface_library == None
    ):
        return cc_common.create_linking_context()

    # Preserve the facade's explicit artifact selection exactly. Re-grouping by
    # basename can split one logical native library into multiple linker inputs,
    # which diverges from cc_import on Windows when the import and static
    # libraries intentionally use different names.
    library_to_link = cc_common.create_library_to_link(
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        static_library = selected.static_library,
        pic_static_library = selected.pic_static_library,
        interface_library = selected.interface_library,
        dynamic_library = selected.shared_library,
        alwayslink = ctx.attr.alwayslink,
    )
    return cc_common.create_linking_context(
        linker_inputs = depset(direct = [
            cc_common.create_linker_input(
                owner = ctx.label,
                libraries = depset(direct = [library_to_link]),
                user_link_flags = depset(direct = ctx.attr.linkopts),
            ),
        ]),
    )

def _collect_transitive_shared_libraries(cc_info):
    shared_libraries = []
    for linker_input in cc_info.linking_context.linker_inputs.to_list():
        for lib in linker_input.libraries:
            if lib.dynamic_library:
                shared_libraries.append(lib.dynamic_library)
    return shared_libraries

def _pretty_label(label):
    label = _as_label(label)
    s = str(label)
    if s.startswith("@@//") or s.startswith("@//"):  # buildifier: disable=canonical-repository
        return s.lstrip("@")
    return s

def _as_label(value):
    if type(value) == "Target":
        return value.label
    return value

def _get_shared_facade_deps(ctx):
    if len(ctx.attr.deps) and len(ctx.attr.roots):
        fail(
            "You are using the attribute 'roots' and 'deps'. 'deps' is the new name for the attribute 'roots'. The attribute 'roots' will be removed in the future",
            attr = "roots",
        )

    deps = ctx.attr.deps
    if not len(deps):
        deps = ctx.attr.roots
    return deps

def _static_library_linkdeps_map_each(linker_input):
    has_library = False
    for lib in linker_input.libraries:
        if lib.pic_static_library != None or lib.static_library != None or lib.dynamic_library != None or lib.interface_library != None:
            has_library = True
    if not has_library:
        return None
    return _pretty_label(linker_input.owner)

def _static_library_linkopts_map_each(linker_input):
    return linker_input.user_link_flags

def _format_linker_inputs(*, actions, name, linker_inputs, map_each):
    file = actions.declare_file(name)
    args = actions.args().add_all(linker_inputs, map_each = map_each)
    actions.write(output = file, content = args)
    return file

def _declare_static_library_output(*, name, actions, feature_configuration):
    if cc_common.is_enabled(
        feature_configuration = feature_configuration,
        feature_name = "targets_windows",
    ):
        return actions.declare_file(name + ".lib")
    return actions.declare_file("lib" + name + ".a")

def _declare_shared_library_output_from_selected(*, name, actions, feature_configuration, selected_shared, shared_lib_name = ""):
    if shared_lib_name:
        return actions.declare_file(shared_lib_name)
    if cc_common.is_enabled(
        feature_configuration = feature_configuration,
        feature_name = "targets_windows",
    ):
        return actions.declare_file(name + ".dll")
    if selected_shared.basename.endswith(".dylib"):
        return actions.declare_file("lib" + name + ".dylib")
    return actions.declare_file("lib" + name + ".so")

def _declare_shared_interface_output(*, name, actions, feature_configuration, shared_output):
    if cc_common.is_enabled(
        feature_configuration = feature_configuration,
        feature_name = "targets_windows",
    ):
        return actions.declare_file(name + ".if.lib")
    return shared_output

def _is_windows_toolchain(cc_toolchain):
    return "windows" in cc_toolchain.cpu

def _is_darwin_toolchain(cc_toolchain):
    return "darwin" in cc_toolchain.cpu or "macos" in cc_toolchain.cpu

def _is_nop_windows_tool(path):
    normalized = path.replace("\\", "/")
    return normalized.endswith("/wrapper/bin/msvc_nop.bat")

def _shell_single_quote(value):
    return "'" + value.replace("'", "'\"'\"'") + "'"

def _maybe_validate_shared_library(*, ctx, cc_toolchain, runtime_shared, expected_basename):
    validation_output = ctx.actions.declare_file(ctx.label.name + "_shared_validation.txt")

    if _is_windows_toolchain(cc_toolchain):
        ctx.actions.write(
            output = validation_output,
            content = "skipped: Windows shared-library identity validation is unavailable from the public C++ toolchain API\n",
        )
        return validation_output

    command = None
    if _is_darwin_toolchain(cc_toolchain):
        command = """
set -eu
tool=""
if [ -x /usr/bin/otool ]; then
  tool=/usr/bin/otool
elif command -v xcrun >/dev/null 2>&1; then
  tool="$(xcrun -f otool 2>/dev/null || true)"
fi
if [ -z "$tool" ] || [ ! -x "$tool" ]; then
  printf '%s\\n' 'skipped: could not find otool for Darwin shared-library validation' > {out}
  exit 0
fi
install_name="$("$tool" -D {lib} 2>/dev/null | sed -n '2p')"
if [ -z "$install_name" ]; then
  echo "Missing install name for {label} shared library {lib_basename}" >&2
  exit 1
fi
if [ "$(basename "$install_name")" != {expected} ]; then
  echo "Install name mismatch for {label}: expected {expected_print}, got $(basename "$install_name")" >&2
  exit 1
fi
printf '%s\\n' "validated install name: $(basename "$install_name")" > {out}
""".format(
            expected = _shell_single_quote(expected_basename),
            expected_print = expected_basename,
            label = ctx.label,
            lib = _shell_single_quote(runtime_shared.path),
            lib_basename = runtime_shared.basename,
            out = _shell_single_quote(validation_output.path),
        )
    else:
        provider_objdump = getattr(cc_toolchain, "objdump_executable", "")
        objdump_path = provider_objdump if provider_objdump and not _is_nop_windows_tool(provider_objdump) else ""
        command = """
set -eu
tool={tool}
if [ -z "$tool" ] || [ ! -x "$tool" ]; then
  tool="$(command -v objdump 2>/dev/null || true)"
fi
if [ -z "$tool" ] || [ ! -x "$tool" ]; then
  printf '%s\\n' 'skipped: could not find objdump for ELF shared-library validation' > {out}
  exit 0
fi
soname="$("$tool" -p {lib} 2>/dev/null | awk '$1 == "SONAME" {{ print $2; exit }}')"
if [ -z "$soname" ]; then
  echo "Missing SONAME for {label} shared library {lib_basename}" >&2
  exit 1
fi
if [ "$(basename "$soname")" != {expected} ]; then
  echo "SONAME mismatch for {label}: expected {expected_print}, got $(basename "$soname")" >&2
  exit 1
fi
printf '%s\\n' "validated soname: $(basename "$soname")" > {out}
""".format(
            expected = _shell_single_quote(expected_basename),
            expected_print = expected_basename,
            label = ctx.label,
            lib = _shell_single_quote(runtime_shared.path),
            lib_basename = runtime_shared.basename,
            out = _shell_single_quote(validation_output.path),
            tool = _shell_single_quote(objdump_path),
        )

    ctx.actions.run_shell(
        mnemonic = "ValidateSharedLibraryIdentity",
        inputs = [runtime_shared],
        outputs = [validation_output],
        command = command,
        use_default_shell_env = True,
        progress_message = "Validating shared library %{label}",
    )
    return validation_output

def _maybe_validate_static_library(*, name, actions, cc_toolchain, feature_configuration, static_library):
    if not cc_common.action_is_enabled(
        feature_configuration = feature_configuration,
        action_name = ACTION_NAMES.validate_static_library,
    ):
        return None

    validation_output = actions.declare_file(name + "_validation_output.txt")
    validator_path = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = ACTION_NAMES.validate_static_library,
    )
    args = actions.args()
    args.add(static_library)
    args.add(validation_output)

    env = cc_common.get_environment_variables(
        feature_configuration = feature_configuration,
        action_name = ACTION_NAMES.validate_static_library,
        variables = cc_common.empty_variables(),
    )
    execution_requirements_keys = cc_common.get_execution_requirements(
        feature_configuration = feature_configuration,
        action_name = ACTION_NAMES.validate_static_library,
    )

    actions.run(
        executable = validator_path,
        arguments = [args],
        env = env,
        execution_requirements = {k: "" for k in execution_requirements_keys},
        inputs = depset(
            direct = [static_library],
            transitive = [cc_toolchain.all_files],
        ),
        outputs = [validation_output],
        use_default_shell_env = True,
        mnemonic = "ValidateStaticLibrary",
        progress_message = "Validating static library %{label}",
    )

    return validation_output

def _foreign_cc_library_impl(ctx):
    facade_inputs = ctx.attr.src[ForeignCcFacadeInputsInfo]
    selected = _select_library_outputs(ctx, facade_inputs)
    import_like = hasattr(ctx.attr, "system_provided")
    system_provided = getattr(ctx.attr, "system_provided", False)

    if system_provided:
        if ctx.attr.shared_library:
            fail("'shared_library' shouldn't be specified when 'system_provided' is true")
        interface_library = selected.interface_library if selected.interface_library else selected.shared_library
        if interface_library == None and selected.static_library == None:
            fail("'interface_library' should be specified when 'system_provided' is true")
        selected = struct(
            interface_library = interface_library,
            pic_static_library = selected.pic_static_library,
            runtime_shared_files = [],
            shared_library = None,
            static_library = selected.static_library,
        )
    elif import_like and ctx.attr.interface_library and not ctx.attr.shared_library:
        fail("'shared_library' should be specified when 'system_provided' is false")

    compilation_context = _create_compilation_context(ctx, facade_inputs.include_dir, facade_inputs.header_manifest)
    direct_linking_context = _create_selected_linking_context(ctx, selected)
    direct_cc_info = CcInfo(
        compilation_context = compilation_context,
        linking_context = direct_linking_context,
    )
    interface_dep_cc_infos = [
        dep[CcInfo]
        for dep in ctx.attr.deps
    ]
    implementation_dep_cc_infos = [
        dep[CcInfo]
        for dep in getattr(ctx.attr, "implementation_deps", [])
    ]
    merged_linking_context = cc_common.merge_cc_infos(
        cc_infos = [direct_cc_info, facade_inputs.deps_cc_info] + interface_dep_cc_infos + implementation_dep_cc_infos,
    ).linking_context
    merged_compilation_context = cc_common.merge_compilation_contexts(
        compilation_contexts = [
            compilation_context,
            facade_inputs.deps_cc_info.compilation_context,
        ] + [
            dep_cc_info.compilation_context
            for dep_cc_info in interface_dep_cc_infos
        ],
    )
    merged_cc_info = CcInfo(
        compilation_context = merged_compilation_context,
        linking_context = merged_linking_context,
    )
    runfiles = ctx.runfiles()
    if not import_like:
        runfiles = _merge_data_runfiles(ctx, runfiles, getattr(ctx.attr, "data", []))
    for dep in ctx.attr.deps:
        if DefaultInfo in dep:
            runfiles = runfiles.merge(dep[DefaultInfo].default_runfiles)

    return [
        _create_default_info(runfiles),
        merged_cc_info,
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

    merged_dep_cc_info = cc_common.merge_cc_infos(cc_infos = [facade_inputs.deps_cc_info] + [
        dep[CcInfo]
        for dep in ctx.attr.deps
    ])
    runtime_shared_libraries = selected.runtime_shared_files + _collect_transitive_shared_libraries(merged_dep_cc_info)
    runfiles = ctx.runfiles(
        files = [executable] + runtime_shared_libraries + ctx.files.data,
        root_symlinks = {
            executable_runfile_path: selected.binary,
        },
    )
    for dep in ctx.attr.deps:
        if DefaultInfo in dep:
            runfiles = runfiles.merge(dep[DefaultInfo].default_runfiles)
    for data_dep in ctx.attr.data:
        if DefaultInfo in data_dep:
            runfiles = runfiles.merge(data_dep[DefaultInfo].default_runfiles)
    return [
        DefaultInfo(
            executable = executable,
            files = depset([executable]),
            default_runfiles = runfiles,
            data_runfiles = runfiles,
        ),
    ]

def _foreign_cc_static_library_impl(ctx):
    facade_inputs = ctx.attr.src[ForeignCcFacadeInputsInfo]
    selected_static = None
    if ctx.attr.static_library:
        selected_static = _file_by_basename(facade_inputs.static_libraries, ctx.attr.static_library)
        if selected_static == None:
            fail("`static_library` references `{}`, which is not a direct static-library output of `{}`".format(
                ctx.attr.static_library,
                ctx.attr.src.label,
            ))
    else:
        selected_static = _infer_single_file(
            facade_inputs.static_libraries,
            _static_stem,
            "static library",
        ) if facade_inputs.static_libraries else None

    if selected_static == None:
        fail("`foreign_cc_static_library` could not select a direct static-library output from `{}`".format(
            ctx.attr.src.label,
        ))

    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features + ["symbol_check"],
        unsupported_features = ctx.disabled_features,
    )

    wrapped_static_library = _declare_static_library_output(
        name = ctx.label.name,
        actions = ctx.actions,
        feature_configuration = feature_configuration,
    )
    ctx.actions.symlink(
        output = wrapped_static_library,
        target_file = selected_static,
    )

    merged_dep_cc_info = cc_common.merge_cc_infos(cc_infos = [facade_inputs.deps_cc_info] + [
        dep[CcInfo]
        for dep in ctx.attr.deps
    ])
    linker_inputs = merged_dep_cc_info.linking_context.linker_inputs
    linkdeps_file = _format_linker_inputs(
        actions = ctx.actions,
        name = ctx.label.name + "_linkdeps.txt",
        linker_inputs = linker_inputs,
        map_each = _static_library_linkdeps_map_each,
    )
    linkopts_file = _format_linker_inputs(
        actions = ctx.actions,
        name = ctx.label.name + "_linkopts.txt",
        linker_inputs = linker_inputs,
        map_each = _static_library_linkopts_map_each,
    )

    validation_output = _maybe_validate_static_library(
        name = ctx.label.name,
        actions = ctx.actions,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        static_library = wrapped_static_library,
    )

    output_groups = {
        "linkdeps": depset([linkdeps_file]),
        "linkopts": depset([linkopts_file]),
    }
    if validation_output:
        output_groups["_validation"] = depset([validation_output])

    runfiles = ctx.runfiles().merge_all([
        dep[DefaultInfo].default_runfiles
        for dep in ctx.attr.deps
        if DefaultInfo in dep
    ])

    return [
        DefaultInfo(
            files = depset([wrapped_static_library]),
            runfiles = runfiles,
        ),
        OutputGroupInfo(**output_groups),
    ]

def _foreign_cc_shared_library_impl(ctx):
    facade_deps = _get_shared_facade_deps(ctx)
    facade_inputs = ctx.attr.src[ForeignCcFacadeInputsInfo]
    selected = _select_library_outputs(ctx, facade_inputs)

    if selected.shared_library == None:
        fail("`foreign_cc_shared_library` requires a direct shared-library output from `{}`".format(
            ctx.attr.src.label,
        ))

    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    wrapped_shared_library = _declare_shared_library_output_from_selected(
        name = ctx.label.name,
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        selected_shared = selected.shared_library,
        shared_lib_name = ctx.attr.shared_lib_name,
    )
    ctx.actions.symlink(
        output = wrapped_shared_library,
        target_file = selected.shared_library,
    )

    wrapped_interface_library = _declare_shared_interface_output(
        name = ctx.label.name,
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        shared_output = wrapped_shared_library,
    )
    if wrapped_interface_library != wrapped_shared_library:
        interface_target = selected.interface_library if selected.interface_library else selected.shared_library
        ctx.actions.symlink(
            output = wrapped_interface_library,
            target_file = interface_target,
        )

    # Keep the producer's runtime identity in DefaultInfo while the optional
    # CcSharedLibraryInfo path advertises the wrapped shared library for native
    # shared-library interop. Native Windows consumers can therefore see both.
    runfiles = ctx.runfiles(
        files = selected.runtime_shared_files,
    )
    dep_runtime_shared_libraries = []
    for dep in facade_deps:
        dep_runtime_shared_libraries.extend(_collect_transitive_shared_libraries(dep[CcInfo]))
        if DefaultInfo in dep:
            runfiles = runfiles.merge(dep[DefaultInfo].default_runfiles)
    if dep_runtime_shared_libraries:
        runfiles = runfiles.merge(ctx.runfiles(files = dep_runtime_shared_libraries))
    for dep in ctx.attr.dynamic_deps:
        runfiles = runfiles.merge(dep[DefaultInfo].data_runfiles)

    hint_attributes = ["dynamic_deps"]
    if ctx.attr.deps:
        hint_attributes.append("deps")
    elif ctx.attr.roots:
        hint_attributes.append("roots")
    if ctx.attr.exports:
        hint_attributes.append("exports")
    hint_kwargs = {
        "attributes": hint_attributes,
    }
    if ctx.attr.shared_library_owners:
        hint_kwargs["owners"] = ctx.attr.shared_library_owners
    else:
        hint_kwargs["owners"] = [ctx.label]

    providers = [
        DefaultInfo(
            files = depset([wrapped_shared_library]),
            runfiles = runfiles,
        ),
        CcSharedLibraryHintInfo(**hint_kwargs),
    ]

    validation_output = _maybe_validate_shared_library(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        runtime_shared = selected.runtime_shared_files[0],
        expected_basename = selected.runtime_shared_files[0].basename,
    )
    providers.append(OutputGroupInfo(
        interface_library = depset([wrapped_interface_library]),
        main_shared_library_output = depset([wrapped_shared_library]),
        _validation = depset([validation_output]),
    ))
    if ctx.attr.emit_cc_shared_library_info:
        if len(hint_kwargs["owners"]) != 1:
            fail("`emit_cc_shared_library_info` requires exactly one shared-library owner")

        dynamic_deps = []
        transitive_dynamic_deps = []
        for dep in ctx.attr.dynamic_deps:
            if CcSharedLibraryInfo not in dep:
                fail("`emit_cc_shared_library_info` requires every `dynamic_deps` entry to provide `CcSharedLibraryInfo`")
            dynamic_dep_entry = struct(
                exports = dep[CcSharedLibraryInfo].exports,
                linker_input = dep[CcSharedLibraryInfo].linker_input,
                link_once_static_libs = dep[CcSharedLibraryInfo].link_once_static_libs,
            )
            dynamic_deps.append(dynamic_dep_entry)
            transitive_dynamic_deps.append(dep[CcSharedLibraryInfo].dynamic_deps)

        direct_library = cc_common.create_library_to_link(
            actions = ctx.actions,
            feature_configuration = feature_configuration,
            cc_toolchain = cc_toolchain,
            dynamic_library = selected.runtime_shared_files[0],
            interface_library = wrapped_interface_library if wrapped_interface_library != wrapped_shared_library else None,
        )
        export_labels = {}
        for label in (ctx.attr.exports if ctx.attr.exports else facade_deps):
            export_labels[_pretty_label(label)] = True
        for label in ctx.attr.exports_filter:
            export_labels[label] = True
        providers.append(CcSharedLibraryInfo(
            dynamic_deps = depset(
                direct = dynamic_deps,
                transitive = transitive_dynamic_deps,
                order = "topological",
            ),
            exports = export_labels.keys(),
            link_once_static_libs = {
                _pretty_label(label): True
                for label in ctx.attr.link_once_static_libs
            },
            linker_input = cc_common.create_linker_input(
                owner = _as_label(hint_kwargs["owners"][0]),
                libraries = depset([direct_library]),
            ),
        ))

    return providers

foreign_cc_library = rule(
    implementation = _foreign_cc_library_impl,
    attrs = {
        "additional_runtime_shared_libraries": attr.string_list(),
        "alwayslink": attr.bool(default = False),
        "data": attr.label_list(allow_files = True),
        "defines": attr.string_list(),
        "deps": attr.label_list(providers = [CcInfo]),
        "implementation_deps": attr.label_list(
            providers = [CcInfo],
            doc = "Additional link-only CcInfo dependencies, mirroring native `cc_library(implementation_deps = ...)` semantics.",
        ),
        "include_prefix": attr.string(
            default = "",
            doc = "Optional prefix to add to published header paths, mirroring native include remapping behavior.",
        ),
        "includes": attr.string_list(),
        "interface_library": attr.string(default = ""),
        "linkopts": attr.string_list(),
        "pic_static_library": attr.string(default = ""),
        "runtime_shared_library": attr.string(default = ""),
        "shared_library": attr.string(default = ""),
        "src": attr.label(
            mandatory = True,
            providers = [ForeignCcFacadeInputsInfo],
        ),
        "static_library": attr.string(default = ""),
        "static_suffix": attr.string(default = ""),
        "strip_include_prefix": attr.string(
            default = "",
            doc = "Optional prefix to strip from direct installed header paths before applying include_prefix.",
        ),
        "_cc_toolchain": attr.label(
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        ),
    },
    doc = """Projects a raw foreign_cc producer target into a cc_library-like target.

This rule is a consumption facade, not a Bazel-owned compile action. It mirrors
native `cc_library` analysis and provider shape where the raw foreign outputs
carry enough truth to do so honestly. Native attrs that only affect the rule's
own compile actions, such as `local_defines`, `textual_hdrs`, or
`additional_compiler_inputs`, are intentionally not exposed here.
""",
    fragments = CC_EXTERNAL_RULE_FRAGMENTS,
    provides = [CcInfo],
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
)

foreign_cc_import = rule(
    implementation = _foreign_cc_library_impl,
    attrs = {
        "additional_runtime_shared_libraries": attr.string_list(),
        "alwayslink": attr.bool(default = False),
        "data": attr.label_list(allow_files = True),
        "defines": attr.string_list(),
        "deps": attr.label_list(providers = [CcInfo]),
        "include_prefix": attr.string(
            default = "",
            doc = "Optional prefix to add to published header paths, mirroring native include remapping behavior.",
        ),
        "includes": attr.string_list(),
        "interface_library": attr.string(default = ""),
        "linkopts": attr.string_list(),
        "pic_static_library": attr.string(default = ""),
        "runtime_shared_library": attr.string(default = ""),
        "shared_library": attr.string(default = ""),
        "src": attr.label(
            mandatory = True,
            providers = [ForeignCcFacadeInputsInfo],
        ),
        "static_library": attr.string(default = ""),
        "static_suffix": attr.string(default = ""),
        "strip_include_prefix": attr.string(
            default = "",
            doc = "Optional prefix to strip from direct installed header paths before applying include_prefix.",
        ),
        "system_provided": attr.bool(default = False),
        "_cc_toolchain": attr.label(
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        ),
    },
    doc = """Projects a raw foreign_cc producer target into a cc_import-like target.

This facade wraps one selected logical library from a raw foreign producer and
publishes native-like `CcInfo` without pretending to own the original compile
or link step.
""",
    fragments = CC_EXTERNAL_RULE_FRAGMENTS,
    provides = [CcInfo],
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
)

foreign_cc_binary = rule(
    implementation = _foreign_cc_binary_impl,
    attrs = {
        "binary": attr.string(default = ""),
        "data": attr.label_list(allow_files = True),
        "deps": attr.label_list(providers = [CcInfo]),
        "runtime_shared_libraries": attr.string_list(),
        "src": attr.label(
            mandatory = True,
            providers = [ForeignCcFacadeInputsInfo],
        ),
        "_runnable_wrapper_template": attr.label(
            allow_single_file = True,
            default = Label("//foreign_cc/private:runnable_binary_wrapper.sh"),
        ),
    },
    doc = """Projects a raw foreign_cc producer target into a cc_binary-like target.

The facade publishes a Bazel-runnable wrapper around one selected producer
binary plus its runtime shared-library closure. It does not replace the
producer's original compile or link action.
""",
    executable = True,
)

foreign_cc_static_library = rule(
    implementation = _foreign_cc_static_library_impl,
    attrs = {
        "deps": attr.label_list(providers = [CcInfo]),
        "src": attr.label(
            mandatory = True,
            providers = [ForeignCcFacadeInputsInfo],
        ),
        "static_library": attr.string(default = ""),
        "_cc_toolchain": attr.label(
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        ),
    },
    doc = """Projects a raw foreign_cc producer target into a cc_static_library-like target.

This facade wraps one selected prebuilt archive and mirrors the native
`cc_static_library` metadata shape it can represent honestly. It does not
rebuild the archive from Bazel-owned object files.
""",
    fragments = CC_EXTERNAL_RULE_FRAGMENTS,
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
)

foreign_cc_shared_library = rule(
    implementation = _foreign_cc_shared_library_impl,
    attrs = {
        "additional_runtime_shared_libraries": attr.string_list(doc = "Additional direct shared-library outputs from `src` that should be carried in runfiles with the selected runtime shared library."),
        "deps": attr.label_list(providers = [CcInfo], doc = "Additional CcInfo dependencies that should contribute runfiles to this wrapped shared library. When `emit_cc_shared_library_info` is enabled and `exports` is omitted, these deps are treated as the default exported targets, mirroring native `cc_shared_library`'s direct-dep export convention."),
        "dynamic_deps": attr.label_list(doc = "Other shared-library dependencies that should contribute runfiles and, when `emit_cc_shared_library_info` is enabled, must already provide `CcSharedLibraryInfo`."),
        "emit_cc_shared_library_info": attr.bool(default = False, doc = "Opt in to emitting experimental `CcSharedLibraryInfo` for native shared-library interop. This requires exactly one owner and only models the explicit metadata provided to this facade."),
        "exports": attr.label_list(providers = [CcInfo], doc = "Targets this shared library claims to export. This mirrors native `cc_shared_library` analysis metadata; it does not change linker symbol visibility by itself."),
        "exports_filter": attr.string_list(doc = "Additional exported-target claims, mirroring native `cc_shared_library(exports_filter = ...)` analysis metadata for explicit labels."),
        "interface_library": attr.string(default = "", doc = "The direct interface-library output from `src` to project as the facade's interface library. This is mainly used on Windows."),
        "link_once_static_libs": attr.label_list(doc = "Targets that should be treated as single-owner static linkage in the experimental `CcSharedLibraryInfo` path. Include a target here only when duplicate static linkage should raise native-style analysis errors."),
        "roots": attr.label_list(providers = [CcInfo], doc = "Deprecated alias for `deps`, mirroring native `cc_shared_library` compatibility semantics."),
        "runtime_shared_library": attr.string(default = "", doc = "The direct runtime shared-library output from `src` to place in runfiles. When omitted, the facade uses the selected shared library."),
        "shared_lib_name": attr.string(default = "", doc = "Optional custom output filename for the wrapped shared library, mirroring native `cc_shared_library(shared_lib_name = ...)`."),
        "shared_library": attr.string(default = "", doc = "The direct shared-library output from `src` that this facade wraps."),
        "shared_library_owners": attr.label_list(doc = "Explicit owners to publish through `CcSharedLibraryHintInfo` and, when enabled, `CcSharedLibraryInfo`. Omit this to default ownership to the facade target itself."),
        "src": attr.label(
            mandatory = True,
            providers = [ForeignCcFacadeInputsInfo],
        ),
        "_cc_toolchain": attr.label(
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        ),
    },
    doc = """Projects a raw foreign_cc producer target into a cc_shared_library-like target.

This facade mirrors the provider and metadata surfaces that can be represented
honestly from an already-linked foreign shared library. Native link-action attrs
such as `additional_linker_inputs`, `user_link_flags`, and `win_def_file` are
intentionally omitted because this rule does not perform the shared-library link
itself.
""",
    fragments = CC_EXTERNAL_RULE_FRAGMENTS,
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
)
