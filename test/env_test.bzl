"""This contains helpers to run tests that check the environment of the various build systems"""

load("@bazel_lib//lib:expand_template.bzl", "expand_template")
load("@bazel_skylib//rules:diff_test.bzl", "diff_test")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//foreign_cc:make.bzl", "make")

def env_test_make(name, *, check_makevars = None, check_shellvars = None, make_attrs = None, test_attrs = None):
    """ Macro to test the environment of a makefile build

    Args:
        name: str
            prefix to base all the other names on

        check_makevars: dict[str, str]:
            The makevars to check, and their expected values.

        check_shellvars: dict[str, str]:
            The shellvars to check, and their expected values.

        make_attrs: dict[*, *]:
            additional attrs to pass to the make() rule

        test_attrs: dict[*, *]:
            additional attrs to pass to the diff_test rule
    """
    name = name + "_env_test"

    check_makevars = check_makevars or {}
    check_shellvars = check_shellvars or {}

    # It's just too much effort to make these configurable.
    if type(check_makevars) != "dict":
        fail("check_makevars must be a dict and is not configurable")

    if type(check_shellvars) != "dict":
        fail("check_shellvars must be a dict and is not configurable")

    makefile = name + "_makefile"
    subs = []
    for makevar in sorted(check_makevars.keys()):
        subs.append(
            # should render as $(MYVAR)
            'printf "%s=%s\\n" "{v}" "$$({v})" >> "$$(MAKEVARS_FILE)"'.format(v = makevar),
        )

    for shellvar in check_shellvars.keys():
        subs.append(
            # should render as $${myvar}
            'printf "%s=%s\\n" "{v}" "$$$${{{v}}}" >> "$$(SHELLVARS_FILE)"'.format(v = shellvar),
        )

    expand_template(
        name = makefile,
        template = Label("//test/env_test:Makefile.tmpl"),
        out = makefile + ".out",
        substitutions = {
            "{{VARIABLES}}": "\n\t".join(subs),
        },
        tags = ["manual"],
    )

    make_attrs = make_attrs or {}

    make_attrs.setdefault("tags", []).append("manual")

    build_name = name + "_build"
    make_attrs.update(dict(
        name = build_name,
        lib_source = Label(makefile),
        args = ["-f", "$$EXT_BUILD_ROOT/$(execpath " + str(Label(makefile)) + ")"],
        data = [
            Label(makefile),
        ],
        env = {
            "MAKEVARS_FILE": "$$INSTALLDIR/makevars.out",
            "SHELLVARS_FILE": "$$INSTALLDIR/shellvars.out",
        },
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

    test_attrs = test_attrs or {}
    for n, v in tests.items():
        if not v:
            continue

        actual = name + "_" + n + "_actual"
        native.filegroup(
            name = actual,
            srcs = [build_name],
            output_group = n + ".out",
            tags = ["manual"],
        )

        expected = name + "_" + n + "_expected"
        write_file(
            name = expected,
            out = expected + ".out",
            content = [
                "{}={}".format(k, v)
                for k, v in check_makevars.items()
            ] + [""],
            tags = ["manual"],
        )

        diff_test(
            name = name + "_" + n + "_check",
            file1 = Label(expected),
            file2 = Label(actual),
            **test_attrs
        )
