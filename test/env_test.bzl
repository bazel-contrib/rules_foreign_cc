"""This contains helpers to run tests that check the environment of the various build systems"""

load("@bazel_lib//lib:expand_template.bzl", "expand_template")
load("@bazel_skylib//rules:diff_test.bzl", "diff_test")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//foreign_cc:cmake.bzl", "cmake")
load("//foreign_cc:make.bzl", "make")

def _validate_not_configurable_dict(name, value):
    # These attributes are intentionally non-configurable in these test macros.
    if type(value) != "dict":
        fail("{} must be a dict and is not configurable".format(name))

def _normalize_checked_vars(primary_name, primary, secondary_name, secondary):
    if primary and secondary == None:
        secondary = primary

    primary = primary or {}
    secondary = secondary or {}

    _validate_not_configurable_dict(primary_name, primary)
    _validate_not_configurable_dict(secondary_name, secondary)

    return primary, secondary

def _prepare_build_attrs(attrs, env_updates):
    attrs = dict(attrs or {})
    tags = list(attrs.get("tags", []))
    tags.append("manual")
    attrs["tags"] = tags

    env = dict(attrs.get("env", {}))
    env.update(env_updates)
    attrs["env"] = env

    return attrs

def _create_env_diff_tests(name, build_name, tests, test_attrs):
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
                "{}={}".format(k, values[k])
                for k in sorted(values.keys())
            ] + [""],
            tags = ["manual"],
        )

        diff_test(
            name = name + "_" + n + "_check",
            file1 = Label(expected),
            file2 = Label(actual),
            **test_attrs
        )

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

    check_makevars, check_shellvars = _normalize_checked_vars(
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
        template = Label("//test/env_test:Makefile.tmpl"),
        out = makefile + "/Makefile",
        substitutions = {
            "{{VARIABLES}}": "\n\t".join(subs),
        },
        tags = ["manual"],
    )

    make_attrs = _prepare_build_attrs(make_attrs, {
        "MAKEVARS_FILE": "$$INSTALLDIR/makevars.out",
        "SHELLVARS_FILE": "$$INSTALLDIR/shellvars.out",
    })

    build_name = name + "_build"
    make_attrs.update(dict(
        name = build_name,
        lib_source = Label(makefile),
        #args = ["-f", "$$EXT_BUILD_ROOT/$(execpath " + str(Label(makefile)) + ")"],
        data = [
            Label(makefile),
        ],
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

    _create_env_diff_tests(name, build_name, tests, test_attrs)

def env_test_cmake(name, *, check_cmakevars = None, check_shellvars = None, cmake_attrs = None, test_attrs = None):
    """ Macro to test the environment of a cmake build

    Args:
        name: str
            prefix to base all the other names on

        check_cmakevars: dict[str, str]:
            The cmake variables to check, and their expected values.

        check_shellvars: dict[str, str]:
            The shellvars to check, and their expected values. Defaults to
            check_cmakevars if not set.

        cmake_attrs: dict[*, *]:
            additional attrs to pass to the cmake() rule

        test_attrs: dict[*, *]:
            additional attrs to pass to the diff_test rule
    """
    name = name + "_env_test"

    check_cmakevars, check_shellvars = _normalize_checked_vars(
        "check_cmakevars",
        check_cmakevars,
        "check_shellvars",
        check_shellvars,
    )

    cmakelists = name + "_src"
    subs = []
    for cmakevar in sorted(check_cmakevars.keys()):
        subs.append(
            "file(APPEND \"$$ENV{{CMAKEVARS_FILE}}\" \"{v}=$${{{v}}}\\n\")".format(v = cmakevar),
        )

    for shellvar in sorted(check_shellvars.keys()):
        subs.append(
            "file(APPEND \"$$ENV{{SHELLVARS_FILE}}\" \"{v}=$$ENV{{{v}}}\\n\")".format(v = shellvar),
        )

    expand_template(
        name = cmakelists,
        template = Label("//test/env_test:CMakeLists.txt.tmpl"),
        out = cmakelists + "/CMakeLists.txt",
        substitutions = {
            "{{VARIABLES}}": "\n".join(subs),
        },
        tags = ["manual"],
    )

    cmake_attrs = _prepare_build_attrs(cmake_attrs, {
        "CMAKEVARS_FILE": "$$INSTALLDIR/cmakevars.out",
        "SHELLVARS_FILE": "$$INSTALLDIR/shellvars.out",
    })

    build_name = name + "_build"
    cmake_attrs.update(dict(
        name = build_name,
        lib_source = Label(cmakelists),
        install = False,
        out_headers_only = True,
        out_data_files = [
            "cmakevars.out",
            "shellvars.out",
        ],
    ))

    cmake(**cmake_attrs)

    tests = {
        "cmakevars": check_cmakevars,
        "shellvars": check_shellvars,
    }

    _create_env_diff_tests(name, build_name, tests, test_attrs)
