"""Tests for the runtime_executable adapter."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
load("@rules_cc//cc:defs.bzl", "CcInfo")
load("//foreign_cc:defs.bzl", "runtime_executable")
load("//foreign_cc:providers.bzl", "ForeignCcDepsInfo")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:runtime_executable_info.bzl", "ForeignCcRuntimeExecutableInfo")

# buildifier: disable=bzl-visibility
load("//foreign_cc/private:transitions.bzl", "extra_toolchains_transitioned_foreign_cc_target")

def _fake_foreign_cc_impl(ctx):
    selected = ctx.actions.declare_file(ctx.label.name + "/bin/tool")
    special_chars = ctx.actions.declare_file(ctx.label.name + "/bin/tool-$USER")
    other = ctx.actions.declare_file(ctx.label.name + "/debug/tool")
    shared_library = ctx.actions.declare_file(ctx.label.name + "/lib/libtool.so")
    include_dir = ctx.actions.declare_directory(ctx.label.name + "/include")
    static_library = ctx.actions.declare_file(ctx.label.name + "/lib/libtool.a")
    interface_library = ctx.actions.declare_file(ctx.label.name + "/lib/tool.ifso")
    resource = ctx.actions.declare_file(ctx.label.name + "/share/runtime_resource.txt")

    ctx.actions.write(selected, "#!/usr/bin/env bash\necho selected\n", is_executable = True)
    ctx.actions.write(special_chars, "#!/usr/bin/env bash\necho special chars\n", is_executable = True)
    ctx.actions.write(other, "#!/usr/bin/env bash\necho other\n", is_executable = True)
    ctx.actions.write(shared_library, "shared library\n")
    ctx.actions.run_shell(
        outputs = [include_dir],
        command = "mkdir -p \"$1\" && printf '#define TOOL_H\\n' > \"$1/tool.h\"",
        arguments = [include_dir.path],
    )
    ctx.actions.write(static_library, "static library\n")
    ctx.actions.write(interface_library, "interface library\n")
    ctx.actions.write(resource, "expected runtime resource\n")

    outputs = [
        selected,
        special_chars,
        other,
        shared_library,
        include_dir,
        static_library,
        interface_library,
        resource,
    ]
    return [
        DefaultInfo(
            files = depset(outputs),
            runfiles = ctx.runfiles(),
        ),
        CcInfo(),
        ForeignCcDepsInfo(artifacts = depset()),
        ForeignCcRuntimeExecutableInfo(
            binaries = {
                "debug/tool": other,
                "tools/tool": selected,
                "tools/tool-$USER": special_chars,
            },
            runtime_files = depset([
                include_dir,
                shared_library,
                resource,
            ]),
        ),
        OutputGroupInfo(),
    ]

_fake_foreign_cc = rule(
    implementation = _fake_foreign_cc_impl,
)

def _assert_runtime_executable_contract(env, target_name):
    target = analysistest.target_under_test(env)
    default_info = target[DefaultInfo]

    files = default_info.files.to_list()
    asserts.true(
        env,
        target_name in [file.basename for file in files],
        "adapter executable should be in DefaultInfo.files",
    )
    asserts.true(
        env,
        default_info.files_to_run.executable.basename in [target_name, target_name + ".exe"],
        "adapter files_to_run executable should be the public target launcher",
    )

    runfile_short_paths = [
        file.short_path
        for file in default_info.default_runfiles.files.to_list()
    ]
    asserts.true(
        env,
        "test/runtime_executable_fake/bin/tool" in runfile_short_paths,
        "selected binary should be in runfiles",
    )
    asserts.true(
        env,
        "test/runtime_executable_fake/share/runtime_resource.txt" in runfile_short_paths,
        "declared output resources should be in runfiles",
    )
    asserts.true(
        env,
        "test/runtime_executable_fake/lib/libtool.so" in runfile_short_paths,
        "shared libraries should be in runfiles",
    )
    asserts.true(
        env,
        "test/runtime_executable_fake/include" in runfile_short_paths,
        "include directory should be in runfiles",
    )
    asserts.false(
        env,
        "test/runtime_executable_fake/bin/tool-$USER" in runfile_short_paths,
        "unselected binaries should not be in runtime executable runfiles",
    )
    asserts.false(
        env,
        "test/runtime_executable_fake/debug/tool" in runfile_short_paths,
        "unselected binaries should not be in runtime executable runfiles",
    )
    asserts.false(
        env,
        "test/runtime_executable_fake/lib/libtool.a" in runfile_short_paths,
        "static libraries should not be in runtime executable runfiles",
    )
    asserts.false(
        env,
        "test/runtime_executable_fake/lib/tool.ifso" in runfile_short_paths,
        "interface libraries should not be in runtime executable runfiles",
    )

# Verifies wrapper mode selects the requested binary, exposes the adapter as the executable,
# and carries the selected binary plus foreign_cc runtime files in runfiles.
def _runtime_executable_exact_binary_test(ctx):
    env = analysistest.begin(ctx)
    _assert_runtime_executable_contract(env, "runtime_executable_exact_subject")
    return analysistest.end(env)

# Verifies runtime_executable fails during analysis when binary does not exactly match
# an entry from the foreign_cc target's declared out_binaries.
def _runtime_executable_invalid_binary_test(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(
        env,
        "runtime_executable binary 'missing' was not found",
    )
    return analysistest.end(env)

# Verifies transitioned foreign_cc wrapper targets preserve the runtime executable metadata.
def _runtime_executable_transitioned_target_test(ctx):
    env = analysistest.begin(ctx)
    _assert_runtime_executable_contract(env, "runtime_executable_transitioned_subject")
    return analysistest.end(env)

runtime_executable_exact_binary_test = analysistest.make(
    _runtime_executable_exact_binary_test,
)

runtime_executable_invalid_binary_test = analysistest.make(
    _runtime_executable_invalid_binary_test,
    expect_failure = True,
)

runtime_executable_transitioned_target_test = analysistest.make(
    _runtime_executable_transitioned_target_test,
)

def runtime_executable_test_suite(name = "runtime_executable_tests"):
    """Defines runtime_executable analysis tests.

    Args:
      name: Name of the generated test suite.
    """
    _fake_foreign_cc(name = "runtime_executable_fake")

    extra_toolchains_transitioned_foreign_cc_target(
        name = "runtime_executable_transitioned_fake",
        target = ":runtime_executable_fake",
    )

    runtime_executable(
        name = "runtime_executable_exact_subject",
        binary = "tools/tool",
        foreign_cc_target = ":runtime_executable_fake",
        tags = ["manual"],
    )

    runtime_executable(
        name = "runtime_executable_invalid_subject",
        binary = "missing",
        foreign_cc_target = ":runtime_executable_fake",
        tags = ["manual"],
    )

    runtime_executable(
        name = "runtime_executable_transitioned_subject",
        binary = "tools/tool",
        foreign_cc_target = ":runtime_executable_transitioned_fake",
        tags = ["manual"],
    )

    runtime_executable(
        name = "runtime_executable_shell_quoting_subject",
        binary = "tools/tool-$USER",
        foreign_cc_target = ":runtime_executable_fake",
        tags = ["manual"],
    )

    unittest.suite(
        name,
        partial.make(
            runtime_executable_exact_binary_test,
            size = "small",
            target_under_test = ":runtime_executable_exact_subject",
        ),
        partial.make(
            runtime_executable_invalid_binary_test,
            size = "small",
            target_under_test = ":runtime_executable_invalid_subject",
        ),
        partial.make(
            runtime_executable_transitioned_target_test,
            size = "small",
            target_under_test = ":runtime_executable_transitioned_subject",
        ),
    )
