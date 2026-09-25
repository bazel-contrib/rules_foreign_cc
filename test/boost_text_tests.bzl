"""Unit tests for Boost.Build (b2) script creation."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//foreign_cc:boost_build.bzl", "export_for_test")

_TOOLCHAIN_ARGS = ["toolset=clang", "--user-config=user-config.jam"]

# Without a `resource_size` there is no reservation to respect, so b2 keeps its
# own default and we add nothing.
def _no_jobs_leaves_command_untouched_test(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        "./b2 install toolset=clang --with-timer --prefix=.",
        export_for_test.b2_install_command(
            b2_extra_args = ["toolset=clang"],
            user_options = ["--with-timer"],
            jobs = 0,
        ),
    )

    return unittest.end(env)

def _jobs_are_passed_to_b2_test(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        "./b2 install -j3 toolset=clang --user-config=user-config.jam --with-timer --prefix=.",
        export_for_test.b2_install_command(
            b2_extra_args = _TOOLCHAIN_ARGS,
            user_options = ["--with-timer"],
            jobs = 3,
        ),
    )

    return unittest.end(env)

# `resource_size = "serial"` resolves to one cpu with no overcommit, which has
# to reach b2 as -j1 rather than as "no flag at all".
def _serial_size_forces_one_job_test(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        "./b2 install -j1 --prefix=.",
        export_for_test.b2_install_command(
            b2_extra_args = [],
            user_options = [],
            jobs = 1,
        ),
    )

    return unittest.end(env)

# The injected flag goes ahead of user_options so a hand-written -j still wins;
# skip injecting entirely so the command line doesn't carry two of them.
def _user_supplied_jobs_win_test(ctx):
    env = unittest.begin(ctx)

    for user_jobs in [["-j1"], ["-j", "1"]]:
        asserts.equals(
            env,
            "./b2 install " + " ".join(user_jobs) + " --prefix=.",
            export_for_test.b2_install_command(
                b2_extra_args = [],
                user_options = user_jobs,
                jobs = 8,
            ),
        )

    return unittest.end(env)

no_jobs_leaves_command_untouched_test = unittest.make(_no_jobs_leaves_command_untouched_test)
jobs_are_passed_to_b2_test = unittest.make(_jobs_are_passed_to_b2_test)
serial_size_forces_one_job_test = unittest.make(_serial_size_forces_one_job_test)
user_supplied_jobs_win_test = unittest.make(_user_supplied_jobs_win_test)

def boost_script_test_suite():
    unittest.suite(
        "boost_script_test_suite",
        partial.make(no_jobs_leaves_command_untouched_test, size = "small"),
        partial.make(jobs_are_passed_to_b2_test, size = "small"),
        partial.make(serial_size_forces_one_job_test, size = "small"),
        partial.make(user_supplied_jobs_win_test, size = "small"),
    )
