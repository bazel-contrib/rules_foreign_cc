""" Rule for building Boost from sources. """

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load("@rules_cc//cc:defs.bzl", "CcInfo")
load("//foreign_cc/private:cc_toolchain_util.bzl", "absolutize_path_in_str", "get_flags_info", "get_tools_info")
load("//foreign_cc/private:detect_root.bzl", "detect_root")
load(
    "//foreign_cc/private:framework.bzl",
    "CC_EXTERNAL_RULE_ATTRIBUTES",
    "CC_EXTERNAL_RULE_FRAGMENTS",
    "cc_external_rule_impl",
    "create_attrs",
    "expand_locations_and_make_variables",
)
load(
    "//foreign_cc/private:runtime_library_search_directories.bzl",
    "runtime_library_search_directories_enabled",
)
load("//foreign_cc/private/framework:helpers.bzl", "escape_dquote_bash")

def _boost_build_impl(ctx):
    attrs = create_attrs(
        ctx.attr,
        configure_name = "BoostBuild",
        create_configure_script = _create_configure_script,
        tools_data = [],
    )
    return cc_external_rule_impl(ctx, attrs)

def _absolutize(workspace_name, text, force = False):
    return absolutize_path_in_str(workspace_name, "$$EXT_BUILD_ROOT$$/", text, force)

def _join_flags_list(workspace_name, flags):
    return " ".join([escape_dquote_bash(_absolutize(workspace_name, flag)) for flag in flags])

# Map Bazel cc_toolchain.compiler values to b2 toolset names. Returns None
# for compilers we don't recognize, in which case we fall back to today's
# free-feature cmdline route (which has the apple-placeholder caveat).
def _b2_toolset(compiler):
    # `clang-cl` is clang in MSVC mode; b2's clang toolset can't drive it.
    if compiler == "clang-cl":
        return None
    if compiler.startswith("clang"):
        return "clang"
    if compiler.startswith("gcc") or compiler.startswith("mingw-gcc"):
        return "gcc"
    if compiler == "msvc-cl":
        return "msvc"
    return None

def _user_supplied_toolset(user_options):
    for opt in user_options:
        if opt.startswith("toolset=") or opt == "--user-config" or opt.startswith("--user-config="):
            return True
    return False

def _jam_quote(text):
    # b2's jam parser accepts double-quoted strings with backslash escaping.
    # Escape backslashes first, then quotes.
    return text.replace("\\", "\\\\").replace("\"", "\\\"")

def _jam_property_line(prop, flag):
    return "    <{}>\"{}\"".format(prop, _jam_quote(flag))

def _b2_free_feature(workspace_name, name, flags):
    if not flags:
        return ""
    return "{}=\"{}\"".format(name, _join_flags_list(workspace_name, flags))

def _create_configure_script(configureParameters):
    ctx = configureParameters.ctx
    root = detect_root(ctx.attr.lib_source)
    data = ctx.attr.data + ctx.attr.build_data
    user_options = expand_locations_and_make_variables(ctx, ctx.attr.user_options, "user_options", data)

    if runtime_library_search_directories_enabled(ctx):
        fail((
            "ERROR: {} enables runtime_library_search_directories, but " +
            "runtime_library_search_directories is not supported by the " +
            "boost_build rule."
        ).format(ctx.label))

    flags = get_flags_info(ctx)
    cc_toolchain = find_cpp_toolchain(ctx)
    tools = get_tools_info(ctx)

    toolset = _b2_toolset(cc_toolchain.compiler)
    pin_compiler = toolset and not _user_supplied_toolset(user_options)

    script = [
        "cd $INSTALLDIR",
        "##copy_dir_contents_to_dir## $$EXT_BUILD_ROOT$$/{}/. .".format(root),
        "chmod -R +w .",
        "##enable_tracing##",
        "./bootstrap.sh {}".format(" ".join(ctx.attr.bootstrap_options)),
    ]

    b2_extra_args = []
    if pin_compiler:
        # Pin b2 to the Bazel cc_toolchain compiler via a generated
        # `user-config.jam`. Without this b2 discovers `clang++`/`g++` from
        # PATH and bypasses any toolchain wrappers — on apple this means
        # placeholders like __BAZEL_XCODE_SDKROOT__ leak through to clang
        # because apple_support's `wrapped_clang` shim never runs.
        absolute_cxx = _absolutize(ctx.workspace_name, tools.cxx, True)
        jam_lines = ["using {} : : \"{}\" :".format(toolset, absolute_cxx)]
        for flag in flags.cxx:
            jam_lines.append(_jam_property_line("cxxflags", flag))
        for flag in flags.cxx_linker_executable:
            jam_lines.append(_jam_property_line("linkflags", flag))
        jam_lines.append("    ;")

        # Note: unquoted heredoc so $$EXT_BUILD_ROOT$$ in the compiler path
        # expands. Toolchain flags don't contain literal `$`, so unquoted is
        # safe; if that ever changes we'd need to split the heredoc.
        script.append("cat > user-config.jam <<EOF")
        script.extend(jam_lines)
        script.append("EOF")
        b2_extra_args.append("--user-config=user-config.jam")
        b2_extra_args.append("toolset={}".format(toolset))
    else:
        b2_extra_args.extend([
            opt
            for opt in [
                _b2_free_feature(ctx.workspace_name, "cxxflags", flags.cxx),
                _b2_free_feature(ctx.workspace_name, "linkflags", flags.cxx_linker_executable),
            ]
            if opt
        ])

    script.append("./b2 install {} {} --prefix=.".format(" ".join(b2_extra_args), " ".join(user_options)))
    script.append("##disable_tracing##")
    return script

def _attrs():
    attrs = dict(CC_EXTERNAL_RULE_ATTRIBUTES)
    attrs.pop("targets")
    attrs.update({
        "bootstrap_options": attr.string_list(
            doc = "any additional flags to pass to bootstrap.sh",
            mandatory = False,
        ),
        "user_options": attr.string_list(
            doc = "any additional flags to pass to b2",
            mandatory = False,
        ),
    })
    return attrs

boost_build = rule(
    doc = "Rule for building Boost. Invokes bootstrap.sh and then b2 install.",
    attrs = _attrs(),
    fragments = CC_EXTERNAL_RULE_FRAGMENTS,
    output_to_genfiles = True,
    provides = [CcInfo],
    implementation = _boost_build_impl,
    toolchains = [
        "@rules_foreign_cc//foreign_cc/private/framework:shell_toolchain",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
)
