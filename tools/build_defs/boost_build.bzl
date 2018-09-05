""" Rule for building Boost from sources. """

load(
    "//tools/build_defs:framework.bzl",
    "CC_EXTERNAL_RULE_ATTRIBUTES",
    "cc_external_rule_impl",
    "create_attrs",
)
load("//tools/build_defs:detect_root.bzl", "detect_root")

def _boost_build(ctx):
    root = detect_root(ctx.attr.lib_source)

    configure_script = "\n".join([
        "cd $INSTALLDIR",
        "cp -R $EXT_BUILD_ROOT/{}/. .".format(root),
        "./bootstrap.sh",
    ])

    attrs = create_attrs(
        ctx.attr,
        configure_name = "BuildBoost",
        configure_script = configure_script,
        make_commands = ["./b2 install --prefix=."],
        static_libraries = [
          "libboost_atomic.a",
          "libboost_chrono.a",
          "libboost_container.a",
          "libboost_context.a",
          "libboost_contract.a",
          "libboost_coroutine.a",
          "libboost_date_time.a",
          "libboost_exception.a",
          "libboost_fiber.a",
          "libboost_filesystem.a",
          "libboost_graph.a",
          "libboost_iostreams.a",
          "libboost_locale.a",
          "libboost_log.a",
          "libboost_log_setup.a",
          "libboost_math_c99.a",
          "libboost_math_c99f.a",
          "libboost_math_c99l.a",
          "libboost_math_tr1.a",
          "libboost_math_tr1f.a",
          "libboost_math_tr1l.a",
          "libboost_numpy27.a",
          "libboost_prg_exec_monitor.a",
          "libboost_program_options.a",
          "libboost_python27.a",
          "libboost_random.a",
          "libboost_regex.a",
          "libboost_serialization.a",
          "libboost_signals.a",
          "libboost_stacktrace_addr2line.a",
          "libboost_stacktrace_backtrace.a",
          "libboost_stacktrace_basic.a",
          "libboost_stacktrace_noop.a",
          "libboost_system.a",
          "libboost_test_exec_monitor.a",
          "libboost_thread.a",
          "libboost_timer.a",
          "libboost_type_erasure.a",
          "libboost_unit_test_framework.a",
          "libboost_wave.a",
          "libboost_wserialization.a",
]
    )
    return cc_external_rule_impl(ctx, attrs)

""" Rule for building Boost. Invokes bootstrap.sh and then b2 install.
  Attributes:
    boost_srcs - target with the boost sources
"""
boost_build = rule(
    attrs = CC_EXTERNAL_RULE_ATTRIBUTES,
    fragments = ["cpp"],
    output_to_genfiles = True,
    implementation = _boost_build,
)
