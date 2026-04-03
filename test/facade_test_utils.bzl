"""Shared test-only helpers for facade parity fixtures."""

load("@bazel_skylib//lib:unittest.bzl", "asserts")
load("@rules_cc//cc:defs.bzl", "CcInfo")
load("@rules_testing//lib:analysis_test.bzl", "analysis_test")
load("@rules_testing//lib:truth.bzl", "matching")
load("//foreign_cc:providers.bzl", "ForeignCcFacadeInputsInfo")

def _select_foreign_output_impl(ctx):
    facade_inputs = ctx.attr.src[ForeignCcFacadeInputsInfo]
    candidates = (
        facade_inputs.binary_files +
        facade_inputs.shared_libraries +
        facade_inputs.interface_libraries +
        facade_inputs.static_libraries
    )
    matches = [file for file in candidates if file.basename == ctx.attr.basename]
    if len(matches) != 1:
        fail("Expected exactly one foreign output named `{}` from `{}`, found `{}`".format(
            ctx.attr.basename,
            ctx.attr.src.label,
            [file.basename for file in matches],
        ))

    return [DefaultInfo(files = depset(matches))]

select_foreign_output = rule(
    implementation = _select_foreign_output_impl,
    attrs = {
        "basename": attr.string(mandatory = True),
        "src": attr.label(
            mandatory = True,
            providers = [ForeignCcFacadeInputsInfo],
        ),
    },
)

def default_files_basenames(target):
    """Returns sorted basenames from DefaultInfo.files.

    Args:
      target: Analysed target exposing DefaultInfo.

    Returns:
      A sorted list of basenames from DefaultInfo.files.
    """
    return sorted([file.basename for file in target[DefaultInfo].files.to_list()])

def output_group_basenames(target, name):
    """Returns sorted basenames from one output group.

    Args:
      target: Analysed target exposing OutputGroupInfo.
      name: Output-group field name.

    Returns:
      A sorted list of basenames from the named output group.
    """
    return sorted([file.basename for file in getattr(target[OutputGroupInfo], name).to_list()])

def has_output_group(target, name):
    """Returns whether the target exposes the output group.

    Args:
      target: Analysed target exposing OutputGroupInfo.
      name: Output-group field name.

    Returns:
      True when the output group exists on the target.
    """
    return hasattr(target[OutputGroupInfo], name)

def default_runfiles_basenames(target):
    """Returns unique non-directory basenames from default runfiles.

    Args:
      target: Analysed target exposing DefaultInfo.

    Returns:
      A sorted list of unique basenames from default runfiles.
    """
    basenames = {}
    for file in target[DefaultInfo].default_runfiles.files.to_list():
        if file.is_directory:
            continue
        basenames[file.basename] = True
    return sorted(basenames.keys())

def normalize_include_path(path):
    """Reduces include roots to a stable suffix for parity checks.

    Args:
      path: Include root path from a compilation context.

    Returns:
      A normalized path suffix anchored at `/include` when present.
    """
    normalized = path.replace("\\", "/")
    include_start = normalized.rfind("/include")
    if include_start == -1:
        return normalized
    return normalized[include_start:]

def system_includes(target):
    """Returns normalized system include roots from CcInfo.

    Args:
      target: Analysed target exposing CcInfo.

    Returns:
      A sorted list of normalized system include roots.
    """
    includes = target[CcInfo].compilation_context.system_includes.to_list()
    basenames = {}
    for include in includes:
        basenames[normalize_include_path(include)] = True
    return sorted(basenames.keys())

def cc_defines(target):
    """Returns sorted transitive defines from CcInfo.

    Args:
      target: Analysed target exposing CcInfo.

    Returns:
      A sorted list of transitive defines.
    """
    return sorted(target[CcInfo].compilation_context.defines.to_list())

def cc_linkopts(target):
    """Returns sorted user link flags from linker inputs.

    Args:
      target: Analysed target exposing CcInfo.

    Returns:
      A sorted list of transitive user link flags.
    """
    linker_inputs = target[CcInfo].linking_context.linker_inputs.to_list()
    linkopts = []
    for linker_input in linker_inputs:
        user_link_flags = linker_input.user_link_flags
        if type(user_link_flags) == "depset":
            user_link_flags = user_link_flags.to_list()
        linkopts.extend(user_link_flags)
    return sorted(linkopts)

def cc_library_to_link_structs(target):
    """Returns simplified linker-library structs from a target CcInfo.

    Args:
      target: Analysed target exposing CcInfo.

    Returns:
      A list of simplified linker-library structs for parity assertions.
    """
    linker_inputs = target[CcInfo].linking_context.linker_inputs.to_list()
    libraries = []
    for linker_input in linker_inputs:
        for library in linker_input.libraries:
            libraries.append(struct(
                alwayslink = library.alwayslink,
                dynamic = library.dynamic_library.basename if library.dynamic_library else "",
                interface = library.interface_library.basename if library.interface_library else "",
                pic_static = library.pic_static_library.basename if library.pic_static_library else "",
                static = library.static_library.basename if library.static_library else (
                    library.pic_static_library.basename if library.pic_static_library else ""
                ),
            ))
    return libraries

def cc_library_summary(target, *, include_alwayslink = False, include_pic_static = False):
    """Returns a stable string summary for all linker libraries.

    Args:
      target: Analysed target exposing CcInfo.
      include_alwayslink: Whether to include the alwayslink bit in each entry.
      include_pic_static: Whether to include the PIC static basename in each entry.

    Returns:
      A sorted list of stable string summaries for all linker libraries.
    """
    libraries = cc_library_to_link_structs(target)
    summary = []
    for lib in libraries:
        parts = [lib.dynamic, lib.interface, lib.static]
        if include_pic_static:
            parts.append(lib.pic_static)
        if include_alwayslink:
            parts.append(str(lib.alwayslink))
        summary.append("|".join(parts))
    return sorted(summary)

def selected_cc_library(target):
    """Returns the first linker library from the target CcInfo.

    Args:
      target: Analysed target exposing CcInfo.

    Returns:
      The first simplified linker-library struct from the target.
    """
    libraries = cc_library_to_link_structs(target)
    if not libraries:
        fail("Expected at least one library in linking context")
    return libraries[0]

def assert_contains_all(env, actual, expected):
    """Asserts that every expected item is present in the actual list.

    Args:
      env: analysistest environment.
      actual: Actual string collection.
      expected: Expected subset of the actual collection.
    """
    actual_set = {}
    for item in actual:
        actual_set[item] = True

    missing = []
    for item in expected:
        if item not in actual_set:
            missing.append(item)

    asserts.equals(env, [], missing)

def expect_failure_test(*, name, target, failure_message):
    """Declares a rules_testing analysis failure check."""

    def _impl(env, analysed_target):
        env.expect.that_target(analysed_target).failures().contains_predicate(
            matching.contains(failure_message),
        )

    analysis_test(
        name = name,
        expect_failure = True,
        impl = _impl,
        target = target,
    )

def analysis_smoke_test(*, name, target):
    """Declares a no-op analysis test that only checks loading succeeds."""

    def _impl(_, _target):
        return

    analysis_test(
        name = name,
        impl = _impl,
        target = target,
    )
