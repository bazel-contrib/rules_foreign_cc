"""Unit tests for meson script creation."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//foreign_cc:meson.bzl", "export_for_test")

def _list_to_str_repr_test(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, "['a']", export_for_test.list_to_str_repr(["a"]))
    asserts.equals(env, "['a', 'b']", export_for_test.list_to_str_repr(["a", "b"]))
    asserts.equals(env, "[]", export_for_test.list_to_str_repr([]))

    # Flags with commas must be quoted so meson treats them as single array elements.
    asserts.equals(env, "['a,b', 'c,d']", export_for_test.list_to_str_repr(["a,b", "c,d"]))

    # Flags that look like linker options are passed through unchanged.
    asserts.equals(
        env,
        "['--sysroot=/some/path', '-fuse-ld=lld']",
        export_for_test.list_to_str_repr(["--sysroot=/some/path", "-fuse-ld=lld"]),
    )

    return unittest.end(env)

list_to_str_repr_test = unittest.make(_list_to_str_repr_test)

def _runtime_script_test(ctx):
    env = unittest.begin(ctx)
    tools = struct(cc = "external/compiler/bin/clang", cxx = "external/compiler/bin/clang++")
    first = struct(path = "bazel-out/bin/runtime/libc++.so.1", dirname = "bazel-out/bin/runtime")
    second = struct(path = "bazel-out/bin/runtime/libunwind.so.1", dirname = "bazel-out/bin/runtime")
    files = [first, second]

    dynamic = "\n".join(export_for_test.runtime_script(tools, files, files))
    static = "\n".join(export_for_test.runtime_script(tools, files, []))
    asserts.true(env, dynamic.index(first.path) < dynamic.index(second.path))
    asserts.true(env, """printf '$"%s"\\n'""" in dynamic)
    for language, compiler in [("c", "cc"), ("cpp", "cpp")]:
        asserts.true(env, "{} = ['''$_rfcc_meson_{}''', '''--config=".format(language, compiler) in dynamic)
    loader_path = "export LD_LIBRARY_PATH=\"$$EXT_BUILD_ROOT$$/\"'bazel-out/bin/runtime'${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    asserts.true(env, dynamic.endswith(loader_path))
    asserts.false(env, "LD_LIBRARY_PATH" in static)
    return unittest.end(env)

runtime_script_test = unittest.make(_runtime_script_test)

def meson_script_test_suite():
    unittest.suite(
        "meson_script_test_suite",
        partial.make(list_to_str_repr_test, size = "small"),
        partial.make(runtime_script_test, size = "small"),
    )
