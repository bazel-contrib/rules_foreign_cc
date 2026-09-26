"""Unit tests for runtime library search directory policy.

This suite covers enablement and analysis-time contracts: global auto
enablement, disabled overrides, the Windows explicit-vs-auto split, and
foreign_cc rule failures when shared-library outputs are declared without the
required shared-link flag hook.
"""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private:runtime_library_search_directories.bzl",
    "RUNTIME_LIBRARY_SEARCH_DIRECTORY_ATTRIBUTES",
    "export_for_test",
    "runtime_library_search_directories_enabled",
)

_RuntimeSearchEnabledInfo = provider(
    "Runtime library search directory enablement state.",
    fields = [
        "requested_enabled",
        "enabled",
    ],
)
_RUNTIME_SEARCH_SETTING = str(Label("//foreign_cc/settings:runtime_library_search_directories"))
_UNIX_ONLY = select({
    "@platforms//os:windows": ["@platforms//:incompatible"],
    "//conditions:default": [],
})

def _missing_shared_ldflags_messages(shared_ldflags_hook):
    return [
        "{} is not set".format(shared_ldflags_hook),
        "out_shared_libs",
        "runtime_library_search_directories = \"disabled\"",
    ]

def _runtime_search_enabled_subject_impl(ctx):
    return [_RuntimeSearchEnabledInfo(
        requested_enabled = export_for_test.runtime_library_search_directories_requested(ctx),
        enabled = runtime_library_search_directories_enabled(
            ctx,
            is_windows = ctx.attr.is_windows,
        ),
    )]

_runtime_search_enabled_subject = rule(
    implementation = _runtime_search_enabled_subject_impl,
    attrs = {
        "is_windows": attr.bool(default = False),
    } | dict(RUNTIME_LIBRARY_SEARCH_DIRECTORY_ATTRIBUTES),
)

# Generic enablement test: asserts the (requested, enabled) pair the subject
# resolves to. Inputs (the subject target and global setting) and expectations
# (expected_requested / expected_enabled) both live at the partial.make call
# site, so each case reads as input -> expected in the suite below.
def _enablement_test_impl(ctx):
    env = analysistest.begin(ctx)

    info = analysistest.target_under_test(env)[_RuntimeSearchEnabledInfo]
    asserts.equals(env, ctx.attr.expected_requested, info.requested_enabled, "requested_enabled")
    asserts.equals(env, ctx.attr.expected_enabled, info.enabled, "enabled")

    return analysistest.end(env)

# Generic failure test: asserts every expected_messages substring appears in the
# analysis failure of the target under test.
def _expect_failure_messages_test_impl(ctx):
    env = analysistest.begin(ctx)

    for message in ctx.attr.expected_messages:
        asserts.expect_failure(env, message)

    return analysistest.end(env)

# The global build setting is baked into the rule via config_settings, so each
# global value needs its own rule object. All reuse the one impl.
enablement_test = analysistest.make(
    _enablement_test_impl,
    config_settings = {
        _RUNTIME_SEARCH_SETTING: "enabled",
    },
    attrs = {
        "expected_enabled": attr.bool(mandatory = True),
        "expected_requested": attr.bool(mandatory = True),
    },
)
enablement_disabled_global_test = analysistest.make(
    _enablement_test_impl,
    # No config_settings: the global setting stays at its "disabled" default.
    attrs = {
        "expected_enabled": attr.bool(mandatory = True),
        "expected_requested": attr.bool(mandatory = True),
    },
)
expect_failure_messages_test = analysistest.make(
    _expect_failure_messages_test_impl,
    expect_failure = True,
    attrs = {
        "expected_messages": attr.string_list(mandatory = True),
    },
)
expect_failure_messages_auto_test = analysistest.make(
    _expect_failure_messages_test_impl,
    config_settings = {
        _RUNTIME_SEARCH_SETTING: "enabled",
    },
    expect_failure = True,
    attrs = {
        "expected_messages": attr.string_list(mandatory = True),
    },
)

def runtime_library_search_directories_test_suite_policy(name = "runtime_library_search_directories_test_suite_policy"):
    """Declares runtime-library-search enablement and analysis-policy tests.

    Args:
      name: Name for the generated analysistest suite and helper targets.
    """

    _runtime_search_enabled_subject(
        name = name + "_auto_subject",
        runtime_library_search_directories = "auto",
        tags = ["manual"],
    )
    _runtime_search_enabled_subject(
        name = name + "_disabled_subject",
        runtime_library_search_directories = "disabled",
        tags = ["manual"],
    )
    _runtime_search_enabled_subject(
        name = name + "_enabled_subject",
        runtime_library_search_directories = "enabled",
        tags = ["manual"],
    )
    _runtime_search_enabled_subject(
        name = name + "_windows_explicit_subject",
        is_windows = True,
        runtime_library_search_directories = "enabled",
        tags = ["manual"],
    )
    _runtime_search_enabled_subject(
        name = name + "_windows_auto_subject",
        is_windows = True,
        runtime_library_search_directories = "auto",
        tags = ["manual"],
    )

    unittest.suite(
        name,
        # Enablement matrix. The subject's runtime_library_search_directories
        # attr and the global setting together decide (requested, enabled);
        # "auto" is the only attr value that reads the global setting, and
        # is_windows forces enabled off (explicit "enabled" fails instead; see
        # below). The global setting's own default is "disabled".
        #
        #   subject attr | is_windows | global setting | requested | enabled
        #   -------------+------------+----------------+-----------+--------
        #   auto         | no         | enabled        | True      | True
        #   disabled     | no         | enabled        | False     | False
        #   auto         | yes        | enabled        | True      | False
        #   auto         | no         | disabled       | False     | False
        #   enabled      | no         | disabled       | True      | True
        #
        # Rows 1-3: global setting forced to "enabled" via config_settings.
        partial.make(
            enablement_test,
            name = name + "_auto_uses_global_test",
            size = "small",
            target_under_test = ":" + name + "_auto_subject",
            expected_requested = True,
            expected_enabled = True,
        ),
        partial.make(
            enablement_test,
            name = name + "_disabled_overrides_global_test",
            size = "small",
            target_under_test = ":" + name + "_disabled_subject",
            expected_requested = False,
            expected_enabled = False,
        ),
        partial.make(
            enablement_test,
            name = name + "_windows_auto_noops_test",
            size = "small",
            target_under_test = ":" + name + "_windows_auto_subject",
            expected_requested = True,
            expected_enabled = False,
        ),
        # Rows 4-5 above: global setting left at its "disabled" default.
        partial.make(
            enablement_disabled_global_test,
            name = name + "_auto_follows_global_disabled_test",
            size = "small",
            target_under_test = ":" + name + "_auto_subject",
            expected_requested = False,
            expected_enabled = False,
        ),
        partial.make(
            enablement_disabled_global_test,
            name = name + "_explicit_enabled_ignores_global_test",
            size = "small",
            target_under_test = ":" + name + "_enabled_subject",
            expected_requested = True,
            expected_enabled = True,
        ),
        # Windows explicit "enabled" is a hard analysis failure.
        partial.make(
            expect_failure_messages_test,
            name = name + "_windows_explicit_fails_test",
            size = "small",
            target_under_test = ":" + name + "_windows_explicit_subject",
            expected_messages = [
                "runtime_library_search_directories = \"enabled\"",
                "not supported on Windows",
                name + "_windows_explicit_subject",
            ],
        ),

        # Rules that declare out_shared_libs must wire up the rule-specific
        # shared-link flag hook whenever runtime search is enabled; missing it is
        # a hard analysis failure. The cases below cover each (rule kind x hook
        # attr x enablement path) combination:
        #
        #   rule kind       | hook attr            | enablement   | test rule
        #   ----------------+----------------------+--------------+----------------------------------
        #   make            | shared_ldflags_vars  | explicit     | expect_failure_messages_test
        #   make            | shared_ldflags_vars  | auto+global  | expect_failure_messages_auto_test
        #   configure_make  | shared_ldflags_vars  | explicit     | expect_failure_messages_test
        #   configure_make  | shared_ldflags_vars  | auto+global  | expect_failure_messages_auto_test
        #   meson           | shared_ldflags_option| explicit     | expect_failure_messages_test
        #   meson           | shared_ldflags_option| auto+global  | expect_failure_messages_auto_test
        #
        # "explicit":    sets runtime_library_search_directories = "enabled" on
        #                the target.
        # "auto+global": sets runtime_library_search_directories = "auto" on the
        #                the target and forces the build_setting for the same
        #                feature to be "enabled" via config_settings.
        # All are non-Windows only (_UNIX_ONLY).
        partial.make(
            expect_failure_messages_test,
            name = "runtime_search_make_missing_shared_ldflags_vars_explicit_test",
            size = "small",
            target_under_test = "//test/runtime_search:make_missing_shared_ldflags_vars_explicit",
            expected_messages = _missing_shared_ldflags_messages("shared_ldflags_vars"),
            target_compatible_with = _UNIX_ONLY,
        ),
        partial.make(
            expect_failure_messages_auto_test,
            name = "runtime_search_make_missing_shared_ldflags_vars_auto_test",
            size = "small",
            target_under_test = "//test/runtime_search:make_missing_shared_ldflags_vars_auto",
            expected_messages = _missing_shared_ldflags_messages("shared_ldflags_vars"),
            target_compatible_with = _UNIX_ONLY,
        ),
        partial.make(
            expect_failure_messages_test,
            name = "runtime_search_configure_make_missing_shared_ldflags_vars_explicit_test",
            size = "small",
            target_under_test = "//test/runtime_search:configure_make_missing_shared_ldflags_vars_explicit",
            expected_messages = _missing_shared_ldflags_messages("shared_ldflags_vars"),
            target_compatible_with = _UNIX_ONLY,
        ),
        partial.make(
            expect_failure_messages_auto_test,
            name = "runtime_search_configure_make_missing_shared_ldflags_vars_auto_test",
            size = "small",
            target_under_test = "//test/runtime_search:configure_make_missing_shared_ldflags_vars_auto",
            expected_messages = _missing_shared_ldflags_messages("shared_ldflags_vars"),
            target_compatible_with = _UNIX_ONLY,
        ),
        partial.make(
            expect_failure_messages_test,
            name = "runtime_search_meson_missing_shared_ldflags_option_explicit_test",
            size = "small",
            target_under_test = "//test/runtime_search:meson_missing_shared_ldflags_option_explicit",
            expected_messages = _missing_shared_ldflags_messages("shared_ldflags_option"),
            target_compatible_with = _UNIX_ONLY,
        ),
        partial.make(
            expect_failure_messages_auto_test,
            name = "runtime_search_meson_missing_shared_ldflags_option_auto_test",
            size = "small",
            target_under_test = "//test/runtime_search:meson_missing_shared_ldflags_option_auto",
            expected_messages = _missing_shared_ldflags_messages("shared_ldflags_option"),
            target_compatible_with = _UNIX_ONLY,
        ),
    )
