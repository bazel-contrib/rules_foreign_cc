"""Provider parity tests for the transitive native/foreign matrix."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_cc//cc:defs.bzl", "CcInfo")

def _all_digits(value):
    for char in value.elems():
        if char < "0" or char > "9":
            return False
    return bool(value)

def _strip_pic_static_suffix(name):
    if name.endswith(".pic.a"):
        return name[:-len(".pic.a")] + ".a"
    return name

def _is_versioned_dylib(name, library_name):
    if not name.endswith(".dylib"):
        return False
    stem = name[:-len(".dylib")]
    prefix = library_name + "."
    if not stem.startswith(prefix):
        return False
    return all([_all_digits(part) for part in stem[len(prefix):].split(".")])

def _canonical_static_library_name(name):
    lower_name = _strip_pic_static_suffix(name.lower())
    if lower_name in ["libz.a", "z.lib", "zlib.lib"]:
        return "zlib"
    if lower_name in ["libarchive.a", "archive.lib"]:
        return "libarchive"
    if lower_name.startswith("liblibarchive_static_zlib_") and lower_name.endswith(".a"):
        return "libarchive"
    if lower_name.startswith("libarchive_static_zlib_") and lower_name.endswith(".lib"):
        return "libarchive"
    fail("unknown static library basename: %s" % name)

def _canonical_dynamic_library_name(name):
    lower_name = name.lower()
    if lower_name == "libz.so" or lower_name.startswith("libz.so."):
        return "zlib"
    if lower_name == "libz.dylib" or _is_versioned_dylib(lower_name, "libz"):
        return "zlib"
    if lower_name == "zlib1.dll":
        return "zlib"
    if lower_name == "libarchive.so" or lower_name.startswith("libarchive.so."):
        return "libarchive"
    if lower_name == "libarchive.dylib" or _is_versioned_dylib(lower_name, "libarchive"):
        return "libarchive"
    if lower_name == "archive.dll":
        return "libarchive"
    if lower_name.startswith("libarchive_zlib_") and (
        lower_name.endswith(".so") or lower_name.endswith(".dylib")
    ):
        return "libarchive"
    if lower_name.startswith("archive_zlib_") and lower_name.endswith(".dll"):
        return "libarchive"
    fail("unknown dynamic library basename: %s" % name)

def _canonical_interface_library_name(name):
    lower_name = name.lower()
    if lower_name in ["zlib1.lib", "zlib1.if.lib", "zlib_shared.if.lib"]:
        return "zlib"

    # On Windows, libarchive's CMake shared build emits archive.lib as the
    # import library for archive.dll.
    if lower_name in ["archive.lib", "archive.if.lib", "libarchive_shared.if.lib"]:
        return "libarchive"
    if lower_name.startswith("archive_zlib_") and lower_name.endswith(".if.lib"):
        return "libarchive"
    if lower_name.startswith("libarchive_shared_zlib_") and lower_name.endswith(".if.lib"):
        return "libarchive"
    fail("unknown interface library basename: %s" % name)

def _dedupe_sorted(values):
    return sorted({value: None for value in values}.keys())

def _is_solib_path(short_path):
    return short_path.startswith("_solib_")

def _libraries_to_link(linking_context):
    libraries = []
    user_link_flags = []
    for linker_input in linking_context.linker_inputs.to_list():
        user_link_flags.extend(linker_input.user_link_flags)
        libraries.extend(linker_input.libraries)
    return struct(
        libraries = libraries,
        user_link_flags = _dedupe_sorted(user_link_flags),
    )

def _compilation_projection(compilation_context):
    external_includes = getattr(compilation_context, "external_includes", depset())
    local_defines = getattr(compilation_context, "local_defines", depset())
    include_paths = (
        compilation_context.includes.to_list() +
        compilation_context.quote_includes.to_list() +
        compilation_context.system_includes.to_list() +
        external_includes.to_list()
    )
    return struct(
        defines = _dedupe_sorted(compilation_context.defines.to_list()),
        has_headers = bool(compilation_context.headers.to_list()),
        has_include_paths = bool(include_paths),
        local_defines = _dedupe_sorted(local_defines.to_list()),
    )

def _library_path_shapes(libraries, library_attr, resolved_attr, canonicalize_name):
    shapes = {}
    for library in libraries:
        library_file = getattr(library, library_attr)
        resolved_file = getattr(library, resolved_attr)
        if not library_file and not resolved_file:
            continue

        name = canonicalize_name(
            library_file.basename if library_file else resolved_file.basename,
        )
        if name not in shapes:
            shapes[name] = {
                "all_libraries_are_solibs": True,
                "all_resolved_libraries_are_not_solibs": True,
                "has_library": False,
                "has_resolved_library": False,
            }

        shape = shapes[name]
        if library_file:
            shape["has_library"] = True
            if not _is_solib_path(library_file.short_path):
                shape["all_libraries_are_solibs"] = False
        if resolved_file:
            shape["has_resolved_library"] = True
            if _is_solib_path(resolved_file.short_path):
                shape["all_resolved_libraries_are_not_solibs"] = False

    return [
        struct(
            all_libraries_are_solibs = shapes[name]["all_libraries_are_solibs"],
            all_resolved_libraries_are_not_solibs = shapes[name]["all_resolved_libraries_are_not_solibs"],
            has_library = shapes[name]["has_library"],
            has_resolved_library = shapes[name]["has_resolved_library"],
            name = name,
        )
        for name in sorted(shapes.keys())
    ]

def _linking_projection(linking_context):
    linking_inputs = _libraries_to_link(linking_context)
    static_link_libraries = []
    dynamic_libraries = []
    interface_libraries = []
    for library in linking_inputs.libraries:
        # This is semantic parity, not provider-slot parity. foreign_cc publishes
        # declared out_static_libs as static_library; native cc_library may expose the
        # equivalent archive as pic_static_library.
        if library.static_library:
            static_link_libraries.append(_canonical_static_library_name(library.static_library.basename))
        if library.pic_static_library:
            static_link_libraries.append(_canonical_static_library_name(library.pic_static_library.basename))
        if library.dynamic_library:
            dynamic_libraries.append(_canonical_dynamic_library_name(library.dynamic_library.basename))
        if library.interface_library:
            interface_libraries.append(_canonical_interface_library_name(library.interface_library.basename))
    return struct(
        dynamic_library_path_shapes = _library_path_shapes(
            linking_inputs.libraries,
            "dynamic_library",
            "resolved_symlink_dynamic_library",
            _canonical_dynamic_library_name,
        ),
        dynamic_libraries = _dedupe_sorted(dynamic_libraries),
        interface_library_path_shapes = _library_path_shapes(
            linking_inputs.libraries,
            "interface_library",
            "resolved_symlink_interface_library",
            _canonical_interface_library_name,
        ),
        interface_libraries = _dedupe_sorted(interface_libraries),
        static_link_libraries = _dedupe_sorted(static_link_libraries),
        user_link_flags = linking_inputs.user_link_flags,
    )

def _cc_info_projection(target):
    cc_info = target[CcInfo]
    return struct(
        compilation = _compilation_projection(cc_info.compilation_context),
        linking = _linking_projection(cc_info.linking_context),
    )

def _provider_semantic_parity_test_impl(ctx):
    env = analysistest.begin(ctx)
    actual = _cc_info_projection(analysistest.target_under_test(env))
    expected = _cc_info_projection(ctx.attr.expected)

    asserts.equals(env, expected.compilation, actual.compilation, "compilation context")
    asserts.equals(env, expected.linking, actual.linking, "linking context")

    return analysistest.end(env)

_provider_semantic_parity_test = analysistest.make(
    _provider_semantic_parity_test_impl,
    attrs = {
        "expected": attr.label(mandatory = True, providers = [CcInfo]),
    },
)

def provider_semantic_parity_test(name, actual, expected, **kwargs):
    _provider_semantic_parity_test(
        name = name,
        target_under_test = actual,
        expected = expected,
        **kwargs
    )
