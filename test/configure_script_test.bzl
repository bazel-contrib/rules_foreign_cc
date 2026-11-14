"""Tests the placement of runtime libraries in configure and make commands."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:configure_script.bzl", "create_configure_script")

def _script(runtime_paths = [], runtime_dirs = []):
    return create_configure_script(
        workspace_name = "workspace",
        tools = struct(ar = "", cc = "clang", cxx = "clang++", cxx_linker_static = "", ld = ""),
        flags = struct(),
        root = "source",
        user_options = [],
        configure_prefix = "",
        configure_command = "configure",
        deps = [],
        inputs = struct(ext_build_dirs = [], libs = [], include_dirs = [], headers = []),
        env_vars = {},
        regen_env_vars = {},
        configure_in_place = False,
        prefix_flag = "--prefix=",
        autoconf = False,
        autoconf_options = [],
        autoreconf = False,
        autoreconf_options = [],
        autogen = False,
        autogen_command = "",
        autogen_options = [],
        make_prefix = "",
        make_path = "/tools/make",
        make_targets = ["all", "install"],
        make_args = "",
        executable_ldflags_vars = [],
        shared_ldflags_vars = [],
        dynamic_module_ldflags_vars = [],
        is_msvc = False,
        runtime_paths = runtime_paths,
        runtime_dirs = runtime_dirs,
    )

def _runtime_libs_test(ctx):
    env = unittest.begin(ctx)
    no_runtime = _script()
    static = _script(runtime_paths = ["out/libc++.a", "out/libc++abi.a"])
    dynamic = _script(
        runtime_paths = ["out/libc++.so", "other/libc++abi.so"],
        runtime_dirs = ["out", "other"],
    )

    configure_command = '"$$EXT_BUILD_ROOT$$/source/configure" '
    configure = [line for line in no_runtime if configure_command in line][0]
    asserts.false(env, "LIBS=" in configure)
    asserts.equals(env, [
        'LIBS="${LIBS:+$LIBS }$$EXT_BUILD_ROOT$$/out/libc++.a $$EXT_BUILD_ROOT$$/out/libc++abi.a" ' + configure,
    ], [line for line in static if configure_command in line])
    asserts.equals(env, [
        'LIBS="${LIBS:+$LIBS }$$EXT_BUILD_ROOT$$/out/libc++.so $$EXT_BUILD_ROOT$$/other/libc++abi.so" ' + configure,
    ], [line for line in dynamic if configure_command in line])
    asserts.equals(env, [
        'export LD_LIBRARY_PATH="$$EXT_BUILD_ROOT$$/out:$$EXT_BUILD_ROOT$$/other${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"',
    ], [line for line in dynamic if line.startswith("export LD_LIBRARY_PATH=")])

    # Make keeps the Makefile's LIBS, including anything discovered by configure.
    make_commands = [line for line in no_runtime if line.startswith("/tools/make ")]
    asserts.equals(env, make_commands, [line for line in static if line.startswith("/tools/make ")])
    asserts.equals(env, make_commands, [line for line in dynamic if line.startswith("/tools/make ")])
    return unittest.end(env)

configure_runtime_libs_test = unittest.make(_runtime_libs_test)
