load("//for_workspace:repositories.bzl", "repositories")
load(
    "//tools/build_defs/shell_toolchain/toolchains:ws_defs.bzl",
    shell_toolchain_workspace_initalization = "workspace_part",
)
load("//for_workspace:bazel_version.bzl", "bazel_version")

def _read_build_options_impl(rctx):
    _build_tools(rctx)
    rctx.file("BUILD.bazel", _build_mode(rctx))
    rctx.file("bazel_version.bzl", "BAZEL_VERSION=\"{}\"".format(native.bazel_version))

def _build_mode(rctx):
    path = rctx.path(Label("//for_workspace:compilation_mode.bzl"))
    rctx.template("compilation_mode.bzl", path)

    return """
load("//:compilation_mode.bzl", "compilation_mode")

config_setting(
  name = "is_debug",
  values = {"compilation_mode": "dbg"}
)

compilation_mode(
  name = "compilation_mode",
  is_debug = select({
    ":is_debug": True,
    "//conditions:default": False,
}),
  visibility = ["//visibility:public"],
)
"""

def _build_tools(rctx):
    rctx.file(
        "tools.bzl",
        """NINJA_USE_BUILT=False
NINJA_COMMAND="ninja"
NINJA_DEP=[]
CMAKE_USE_BUILT=False
CMAKE_COMMAND="cmake"
CMAKE_DEP=[]

print("Please remove usage of @foreign_cc_platform_utils//:tools.bzl, as it is no longer needed.")
print("To specify the custom cmake and/or ninja tool, use the toolchains registration with \
rules_foreign_cc_dependencies() parameters.")
""",
    )

_read_build_options = repository_rule(
    implementation = _read_build_options_impl,
    environ = ["PATH"],
)

def rules_foreign_cc_dependencies(
        native_tools_toolchains = [],
        register_default_tools = True,
        additonal_shell_toolchain_mappings = [],
        additonal_shell_toolchain_package = None):
    """ Call this function from the WORKSPACE file to initialize rules_foreign_cc
     dependencies and let neccesary code generation happen
     (Code generation is needed to support different variants of the C++ Starlark API.).

     Args:
        native_tools_toolchains: pass the toolchains for toolchain types
        '@rules_foreign_cc//tools/build_defs:cmake_toolchain' and
        '@rules_foreign_cc//tools/build_defs:ninja_toolchain' with the needed platform constraints.
        If you do not pass anything, registered default toolchains will be selected (see below).

        register_default_tools: if True, the cmake and ninja toolchains, calling corresponding
        preinstalled binaries by name (cmake, ninja) will be registered after
        'native_tools_toolchains' without any platform constraints.
        The default is True.

        additonal_shell_toolchain_mappings: mappings of the shell toolchain functions to
        execution and target platforms constraints. Similar to what defined in
        @rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:toolchain_mappings.bzl
        in the TOOLCHAIN_MAPPINGS list.
        Please refer to example in @rules_foreign_cc//toolchain_examples.

        additonal_shell_toolchain_package: a package under which additional toolchains, referencing
        the generated data for the passed additonal_shell_toolchain_mappings, will be defined.
        This value is needed since register_toolchains() is called for these toolchains.
        Please refer to example in @rules_foreign_cc//toolchain_examples.
    """
    repositories()
    _read_build_options(name = "foreign_cc_platform_utils")
    bazel_version(name = "rules_foreign_cc_bazel_version")

    shell_toolchain_workspace_initalization(
        additonal_shell_toolchain_mappings,
        additonal_shell_toolchain_package,
    )

    native.register_toolchains(*native_tools_toolchains)
    if register_default_tools:
        native.register_toolchains(
            "@rules_foreign_cc//tools/build_defs:preinstalled_cmake_toolchain",
            "@rules_foreign_cc//tools/build_defs:preinstalled_ninja_toolchain",
        )
