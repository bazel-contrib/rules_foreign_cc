"""Macro to test the environment of a meson build."""

load("@bazel_lib//lib:expand_template.bzl", "expand_template")
load("//foreign_cc:meson.bzl", "meson")
load(":utils.bzl", "create_env_diff_tests", "normalize_checked_vars", "prepare_build_attrs")

def env_test_meson(name, *, check_shellvars = None, meson_attrs = None, test_attrs = None):
    """Macro to test the environment of a meson build

    Args:
        name: str
            prefix to base all the other names on

        check_shellvars: dict[str, str]:
            The shellvars to check, and their expected values.

        meson_attrs: dict[*, *]:
            additional attrs to pass to the meson() rule

        test_attrs: dict[*, *]:
            additional attrs to pass to the diff_test rule
    """
    name = name + "_env_test"

    check_shellvars = normalize_checked_vars("check_shellvars", check_shellvars)

    meson_build = name + "_src"
    subs = []
    for shellvar in sorted(check_shellvars):
        subs.append(
            "run_command('sh', '-c', 'printf \"%s=%s\\\\n\" \"" + shellvar + "\" \"$${" + shellvar + "}\" >> \"$$SHELLVARS_FILE\"', check: true)",
        )

    expand_template(
        name = meson_build,
        template = Label(":meson.build.tmpl"),
        out = meson_build + "/meson.build",
        substitutions = {
            "{{VARIABLES}}": "\n".join(subs),
        },
        tags = ["manual"],
    )

    meson_attrs = prepare_build_attrs(meson_attrs, {
        "SHELLVARS_FILE": "$$INSTALLDIR/shellvars.out",
    })

    build_name = name + "_build"
    meson_attrs.update(dict(
        name = build_name,
        lib_source = Label(meson_build),
        out_include_dir = "",
        out_headers_only = True,
        targets = [],
        out_data_files = [
            "shellvars.out",
        ],
    ))

    meson(**meson_attrs)

    tests = {
        "shellvars": check_shellvars,
    }

    create_env_diff_tests(name, build_name, tests, test_attrs)
