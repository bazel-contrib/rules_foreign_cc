"""Macro to test the environment of a ninja build."""

load("@bazel_lib//lib:expand_template.bzl", "expand_template")
load("//foreign_cc:ninja.bzl", "ninja")
load(":utils.bzl", "create_env_diff_tests", "normalize_checked_vars", "prepare_build_attrs")

def env_test_ninja(name, *, check_shellvars = None, ninja_attrs = None, test_attrs = None):
    """ Macro to test the environment of a ninja build

    Args:
        name: str
            prefix to base all the other names on

        check_shellvars: dict[str, str]:
            The shellvars to check, and their expected values.

        ninja_attrs: dict[*, *]:
            additional attrs to pass to the ninja() rule

        test_attrs: dict[*, *]:
            additional attrs to pass to the diff_test rule
    """
    name = name + "_env_test"

    check_shellvars, _ = normalize_checked_vars(
        "check_shellvars",
        check_shellvars,
        "check_shellvars",
        None,
    )

    ninjafile = name + "_ninjafile"
    subs = []

    for shellvar in sorted(check_shellvars.keys()):
        subs.append(
            # should render as $${myvar}
            'printf "%s=%s\\n" "{v}" "$$$${v}" >> "$$$$SHELLVARS_FILE"'.format(v = shellvar),
        )

    expand_template(
        name = ninjafile,
        template = Label(":build.ninja.tmpl"),
        out = ninjafile + "/build.ninja",
        substitutions = {
            "{{VARIABLES}}": " && ".join(subs) if subs else "true",
        },
        tags = ["manual"],
    )

    ninja_attrs = prepare_build_attrs(ninja_attrs, {
        "SHELLVARS_FILE": "$$INSTALLDIR/shellvars.out",
    })

    build_name = name + "_build"
    ninja_attrs.update(dict(
        name = build_name,
        lib_source = Label(ninjafile),
        out_headers_only = True,
        targets = [""],
        out_data_files = [
            "shellvars.out",
        ],
    ))

    ninja(**ninja_attrs)

    tests = {
        "shellvars": check_shellvars,
    }

    create_env_diff_tests(name, build_name, tests, test_attrs)
