"""Unit tests for Make environment variable helpers."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//foreign_cc:providers.bzl", "ForeignCcArtifactInfo", "ForeignCcDepsInfo")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:cc_toolchain_util.bzl", "export_for_test")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:make_env_vars.bzl", "get_ldflags_make_vars", "get_make_env_vars")

def _empty_inputs():
    return struct(
        libs = [],
        include_dirs = [],
        headers = [],
        deps_compilation_info = _compilation(),
    )

def _compilation(includes = [], system = [], quote = [], external = []):
    return struct(
        includes = depset(includes),
        system_includes = depset(system),
        quote_includes = depset(quote),
        external_includes = depset(external),
    )

def _inputs(compilation, include_dirs = [], headers = [], libs = []):
    return struct(
        deps_compilation_info = compilation,
        include_dirs = include_dirs,
        headers = headers,
        libs = libs,
    )

def _make_vars(inputs, deps = [], is_msvc = False):
    return get_make_env_vars(
        "workspace",
        struct(cc = None, cxx = None, cxx_linker_static = None, ld = None),
        struct(),
        {},
        deps,
        inputs,
        is_msvc,
        [],
    )

def _header(path):
    return struct(path = path, dirname = path.rsplit("/", 1)[0])

def _foreign_dep(name = "sdk"):
    root = "bazel-out/bin/vendor/copy_" + name + "/" + name
    artifact = ForeignCcArtifactInfo(
        gen_dir = struct(path = root, dirname = root.rsplit("/", 1)[0], basename = name),
        include_dir_name = "include",
        lib_dir_name = "lib",
    )
    return {ForeignCcDepsInfo: ForeignCcDepsInfo(artifacts = depset([artifact]))}

def _dependency_header_classes_test(ctx):
    env = unittest.begin(ctx)
    result = _make_vars(_inputs(
        _compilation(includes = ["ordinary"], system = ["system"], quote = ["quote"], external = ["external"]),
        # The framework's staging list intentionally flattens these classes.
        include_dirs = ["system", "ordinary", "external"],
        headers = [_header("quote/nested/only.h"), _header("system/warning.h")],
    ))
    asserts.equals(env, 'RANLIB=":" LDFLAGS="" CPPFLAGS="-iquote$$EXT_BUILD_ROOT$$/quote -I$$EXT_BUILD_ROOT$$/ordinary -isystem$$EXT_BUILD_ROOT$$/system -isystem$$EXT_BUILD_ROOT$$/external"', result)
    return unittest.end(env)

def _dependency_header_order_test(ctx):
    env = unittest.begin(ctx)
    result = _make_vars(_inputs(
        _compilation(includes = ["ordinary_second", "ordinary_first"], system = ["system_second", "system_first"], quote = ["quote_second", "quote_first"]),
    ))
    asserts.equals(env, 'RANLIB=":" LDFLAGS="" CPPFLAGS="-iquote$$EXT_BUILD_ROOT$$/quote_second -iquote$$EXT_BUILD_ROOT$$/quote_first -I$$EXT_BUILD_ROOT$$/ordinary_second -I$$EXT_BUILD_ROOT$$/ordinary_first -isystem$$EXT_BUILD_ROOT$$/system_second -isystem$$EXT_BUILD_ROOT$$/system_first"', result)
    return unittest.end(env)

def _unclassified_headers_keep_fallback_test(ctx):
    env = unittest.begin(ctx)
    result = _make_vars(_inputs(
        _compilation(system = ["vendor/include"]),
        include_dirs = ["vendor/include", "fallback"],
        headers = [_header("vendor/include/nested/header.h"), _header("vendor/include_extra/header.h"), _header("loose/header.h"), _header("loose/other.h")],
    ))
    asserts.equals(env, 'RANLIB=":" LDFLAGS="" CPPFLAGS="-isystem$$EXT_BUILD_ROOT$$/vendor/include -I$$EXT_BUILD_ROOT$$/fallback -I$$EXT_BUILD_ROOT$$/vendor/include_extra -I$$EXT_BUILD_ROOT$$/loose"', result)
    return unittest.end(env)

def _foreign_sdk_header_classes_test(ctx):
    env = unittest.begin(ctx)
    sdk = _foreign_dep()
    result = _make_vars(_inputs(
        _compilation(system = ["bazel-out/bin/vendor/sdk/include", "bazel-out/bin/vendor/sdk/include/detail"], quote = ["bazel-out/bin/vendor/copy_sdk/sdk/quote"]),
    ), deps = [sdk, sdk])
    asserts.equals(env, 'RANLIB=":" LDFLAGS="-L$$EXT_BUILD_DEPS$$/sdk/lib" CPPFLAGS="-iquote$$EXT_BUILD_DEPS$$/sdk/quote -isystem$$EXT_BUILD_DEPS$$/sdk/include -isystem$$EXT_BUILD_DEPS$$/sdk/include/detail"', result)
    return unittest.end(env)

def _quote_execroot_keeps_header_class_test(ctx):
    env = unittest.begin(ctx)
    for root in [".", ""]:
        result = _make_vars(_inputs(
            _compilation(quote = [root]),
            headers = [_header("package/nested/header.h")],
        ))
        asserts.equals(env, 'RANLIB=":" LDFLAGS="" CPPFLAGS="-iquote$$EXT_BUILD_ROOT$$"', result)
    return unittest.end(env)

def _foreign_sdk_aliases_keep_quote_only_test(ctx):
    env = unittest.begin(ctx)
    result = _make_vars(_inputs(
        _compilation(quote = ["bazel-out/bin/vendor/copy_sdk/sdk/include"]),
        include_dirs = ["bazel-out/bin/vendor/sdk/include"],
        headers = [_header("bazel-out/bin/vendor/sdk/include/nested/header.h")],
    ), deps = [_foreign_dep()])
    asserts.equals(env, 'RANLIB=":" LDFLAGS="-L$$EXT_BUILD_DEPS$$/sdk/lib" CPPFLAGS="-iquote$$EXT_BUILD_DEPS$$/sdk/include"', result)
    return unittest.end(env)

def _foreign_sdk_unclassified_fallback_test(ctx):
    env = unittest.begin(ctx)
    result = _make_vars(_inputs(_compilation()), deps = [_foreign_dep()])
    asserts.equals(env, 'RANLIB=":" LDFLAGS="-L$$EXT_BUILD_DEPS$$/sdk/lib" CPPFLAGS="-I$$EXT_BUILD_DEPS$$/sdk/include"', result)
    return unittest.end(env)

def _msvc_include_flags_unchanged_test(ctx):
    env = unittest.begin(ctx)
    sdk = _foreign_dep()
    result = _make_vars(_inputs(
        _compilation(includes = ["ordinary"], system = ["system"], quote = ["quote"]),
        include_dirs = ["system", "ordinary", "system"],
        headers = [_header("quote/header.h"), _header("loose/header.h"), _header("loose/other.h")],
    ), deps = [sdk, sdk], is_msvc = True)
    asserts.equals(env, 'RANLIB=":" LDFLAGS="-LIBPATH:$$EXT_BUILD_DEPS$$/sdk/lib" CPPFLAGS="-I$$EXT_BUILD_ROOT$$/system -I$$EXT_BUILD_ROOT$$/ordinary -I$$EXT_BUILD_ROOT$$/quote -I$$EXT_BUILD_ROOT$$/loose -I$$EXT_BUILD_DEPS$$/sdk/include"', result)
    return unittest.end(env)

def _ldflags_vars_include_dynamic_modules_test(ctx):
    env = unittest.begin(ctx)

    flags = struct(
        cxx_linker_executable = ["EXE"],
        cxx_linker_shared = ["SHARED"],
        cxx_linker_dynamic_module = ["MODULE"],
    )

    result = get_ldflags_make_vars(
        [],
        [],
        ["MODULE_LDFLAGS"],
        "workspace",
        flags,
        {},
        [],
        _empty_inputs(),
        False,
    )

    asserts.equals(env, "MODULE_LDFLAGS=\"MODULE\"", result)

    return unittest.end(env)

def _ldflags_vars_keep_link_categories_independent_test(ctx):
    env = unittest.begin(ctx)

    flags = struct(
        cxx_linker_executable = ["EXE"],
        cxx_linker_shared = ["SHARED"],
        cxx_linker_dynamic_module = ["MODULE"],
    )

    result = get_ldflags_make_vars(
        ["LDFLAGS"],
        ["SHARED_LDFLAGS"],
        ["MODULE_LDFLAGS"],
        "workspace",
        flags,
        {},
        [],
        _empty_inputs(),
        False,
    )

    asserts.equals(env, "LDFLAGS=\"EXE\" SHARED_LDFLAGS=\"SHARED\" MODULE_LDFLAGS=\"MODULE\"", result)

    return unittest.end(env)

def _dynamic_module_link_flags_strip_darwin_library_flags_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.dynamic_module_link_flags(
        ["-shared", "-dynamiclib", "-Wl,-rpath,@loader_path/lib"],
        True,
    )

    asserts.equals(env, ["-Wl,-rpath,@loader_path/lib"], result)

    return unittest.end(env)

def _dynamic_module_link_flags_preserve_non_darwin_flags_test(ctx):
    env = unittest.begin(ctx)

    result = export_for_test.dynamic_module_link_flags(
        ["-shared", "-Wl,-rpath,$ORIGIN/lib"],
        False,
    )

    asserts.equals(env, ["-shared", "-Wl,-rpath,$ORIGIN/lib"], result)

    return unittest.end(env)

ldflags_vars_include_dynamic_modules_test = unittest.make(_ldflags_vars_include_dynamic_modules_test)
ldflags_vars_keep_link_categories_independent_test = unittest.make(_ldflags_vars_keep_link_categories_independent_test)
dynamic_module_link_flags_strip_darwin_library_flags_test = unittest.make(_dynamic_module_link_flags_strip_darwin_library_flags_test)
dynamic_module_link_flags_preserve_non_darwin_flags_test = unittest.make(_dynamic_module_link_flags_preserve_non_darwin_flags_test)

dependency_header_classes_test = unittest.make(_dependency_header_classes_test)

dependency_header_order_test = unittest.make(_dependency_header_order_test)

unclassified_headers_keep_fallback_test = unittest.make(_unclassified_headers_keep_fallback_test)

foreign_sdk_header_classes_test = unittest.make(_foreign_sdk_header_classes_test)

foreign_sdk_unclassified_fallback_test = unittest.make(_foreign_sdk_unclassified_fallback_test)

msvc_include_flags_unchanged_test = unittest.make(_msvc_include_flags_unchanged_test)

foreign_sdk_aliases_keep_quote_only_test = unittest.make(_foreign_sdk_aliases_keep_quote_only_test)

quote_execroot_keeps_header_class_test = unittest.make(_quote_execroot_keeps_header_class_test)

def make_env_vars_test_suite():
    unittest.suite(
        "make_env_vars_test_suite",
        partial.make(quote_execroot_keeps_header_class_test, size = "small"),
        partial.make(foreign_sdk_aliases_keep_quote_only_test, size = "small"),
        partial.make(msvc_include_flags_unchanged_test, size = "small"),
        partial.make(foreign_sdk_unclassified_fallback_test, size = "small"),
        partial.make(foreign_sdk_header_classes_test, size = "small"),
        partial.make(unclassified_headers_keep_fallback_test, size = "small"),
        partial.make(dependency_header_order_test, size = "small"),
        partial.make(dependency_header_classes_test, size = "small"),
        partial.make(ldflags_vars_include_dynamic_modules_test, size = "small"),
        partial.make(ldflags_vars_keep_link_categories_independent_test, size = "small"),
        partial.make(dynamic_module_link_flags_strip_darwin_library_flags_test, size = "small"),
        partial.make(dynamic_module_link_flags_preserve_non_darwin_flags_test, size = "small"),
    )
