""" Rule for building CMake from sources. """

load("@rules_foreign_cc//tools/build_defs:detect_root.bzl", "detect_root")

def _cmake_tool(ctx):
    root = detect_root(ctx.attr.cmake_srcs)

    cmake = ctx.actions.declare_directory("cmake")
    script_text = "\n".join([
        "BUILD_DIR=$(pwd)",
        "export BUILD_TMPDIR=$(mktemp -d)",
        "cp -R ./{}/. $BUILD_TMPDIR".format(root),
        "mkdir " + cmake.path,
        "pushd $BUILD_TMPDIR",
        "./bootstrap --prefix=install",
        "make install",
        "cp -a ./install/. $BUILD_DIR/" + cmake.path,
        "popd",
    ])

    ctx.actions.run_shell(
        mnemonic = "BootstrapCMake",
        inputs = ctx.attr.cmake_srcs.files,
        outputs = [cmake],
        tools = [],
        use_default_shell_env = True,
        command = script_text,
        execution_requirements = {"block-network": ""},
    )

    return [DefaultInfo(files = depset([cmake]))]

""" Rule for building CMake. Invokes bootstrap script and make install.
  Attributes:
    cmake_srcs - target with the CMake sources
"""
cmake_tool = rule(
    attrs = {
        "cmake_srcs": attr.label(mandatory = True),
    },
    fragments = ["cpp"],
    output_to_genfiles = True,
    implementation = _cmake_tool,
)
