"""Macro to test the environment of a makefile build."""

load("@bazel_lib//lib:expand_template.bzl", "expand_template")
load("//foreign_cc:make.bzl", "make")
load(":utils.bzl", "create_env_diff_tests", "normalize_checked_vars", "prepare_build_attrs")

def env_test_make(name, *, check_makevars = None, check_shellvars = None, make_attrs = None, test_attrs = None):
    """ Macro to test the environment of a makefile build

    Args:
        name: str
            prefix to base all the other names on

        check_makevars: dict[str, str]:
            The makevars to check, and their expected values.

        check_shellvars: dict[str, str]:
            The shellvars to check, and their expected values. Defaults to
            check_makevars if not set.

        make_attrs: dict[*, *]:
            additional attrs to pass to the make() rule

        test_attrs: dict[*, *]:
            additional attrs to pass to the diff_test rule
    """
    name = name + "_env_test"

    check_makevars, check_shellvars = normalize_checked_vars(
        "check_makevars",
        check_makevars,
        "check_shellvars",
        check_shellvars,
    )

    makefile = name + "_makefile"
    subs = []
    for makevar in sorted(check_makevars.keys()):
        subs.append(
            # should render as $(MYVAR)
            'printf "%s=%s\\n" "{v}" "$$({v})" >> "$$(MAKEVARS_FILE)"'.format(v = makevar),
        )

    for shellvar in sorted(check_shellvars.keys()):
        subs.append(
            # should render as $${myvar}
            'printf "%s=%s\\n" "{v}" "$$$${{{v}}}" >> "$$(SHELLVARS_FILE)"'.format(v = shellvar),
        )

    expand_template(
        name = makefile,
        template = Label(":Makefile.tmpl"),
        out = makefile + "/Makefile",
        substitutions = {
            "{{VARIABLES}}": "\n\t".join(subs),
        },
        tags = ["manual"],
    )

    make_attrs = prepare_build_attrs(make_attrs, {
        "MAKEVARS_FILE": "$$INSTALLDIR/makevars.out",
        "SHELLVARS_FILE": "$$INSTALLDIR/shellvars.out",
    })

    build_name = name + "_build"
    make_attrs.update(dict(
        name = build_name,
        lib_source = Label(makefile),
        out_headers_only = True,
        targets = [""],
        out_data_files = [
            "makevars.out",
            "shellvars.out",
        ],
    ))

    make(**make_attrs)

    tests = {
        "makevars": check_makevars,
        "shellvars": check_shellvars,
    }

    create_env_diff_tests(name, build_name, tests, test_attrs)
