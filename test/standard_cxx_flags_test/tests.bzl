""" TODO """

load("@rules_foreign_cc//tools/build_defs:cc_toolchain_util.bzl", "CxxFlagsInfo", "get_flags_info")

def _impl(ctx):
    flags = get_flags_info(ctx)

    assert_contains_once(flags.assemble, "-fblah0")
    assert_contains_once(flags.assemble, "-fblah2")

    assert_contains_once(flags.cc, "-fblah0")
    assert_contains_once(flags.cc, "-fblah2")

    assert_contains_once(flags.cxx, "-fblah0")
    assert_contains_once(flags.cxx, "-fblah1")

    assert_contains_once(flags.cxx_linker_executable, "-fblah3")
    assert_contains_once(flags.cxx_linker_shared, "-fblah3")
    assert_contains_once(flags.cxx_linker_static, "-fblah3")

# to satisfy test rule requirement to be executable
    ctx.actions.write(
        output = ctx.outputs.executable,
        content = "",
    )

def assert_contains_once(arr, value):
    cnt = 0
    for elem in arr:
        if elem == value:
            cnt = cnt + 1
    if cnt == 0:
        fail("Did not find " + value)
    if cnt > 1:
        fail("Value is included multiple times: " + value)

flags_test = rule(
    implementation = _impl,
    attrs = {
        "_cc_toolchain": attr.label(default = Label("@bazel_tools//tools/cpp:current_cc_toolchain")),
    },
    fragments = ["cpp"],
    test = True,
)
