"""Macro to test the environment of a configure_make build."""

load("@bazel_lib//lib:copy_file.bzl", "copy_file")
load("@bazel_lib//lib:expand_template.bzl", "expand_template")
load("//foreign_cc:configure.bzl", "configure_make")
load(":utils.bzl", "create_env_diff_tests", "normalize_checked_vars", "prepare_build_attrs")

def env_test_configure_make(name, *, check_makevars = None, check_shellvars = None, configure_make_attrs = None, test_attrs = None):
    """Macro to test the environment of a configure_make build

    Args:
        name: str
            prefix to base all the other names on

        check_makevars: dict[str, str]:
            The makevars to check, and their expected values.

        check_shellvars: dict[str, str]:
            The shellvars to check, and their expected values. Defaults to
            check_makevars if not set.

        configure_make_attrs: dict[*, *]:
            additional attrs to pass to the configure_make() rule

        test_attrs: dict[*, *]:
            additional attrs to pass to the diff_test rule
    """
    name = name + "_env_test"

    check_makevars = normalize_checked_vars("check_makevars", check_makevars)
    check_shellvars = normalize_checked_vars("check_shellvars", check_shellvars, default = check_makevars)

    subs = []
    for makevar in sorted(check_makevars):
        subs.append(
            # should render as $(MYVAR)
            'printf "%s=%s\\n" "{v}" "$$({v})" >> "$$(MAKEVARS_FILE)"'.format(v = makevar),
        )

    for shellvar in sorted(check_shellvars):
        subs.append(
            # should render as $${myvar}
            'printf "%s=%s\\n" "{v}" "$$$${{{v}}}" >> "$$(SHELLVARS_FILE)"'.format(v = shellvar),
        )

    src = name + "_src"

    files_to_copy = {
        "configure": src + "_configure",
        "install-sh": src + "_install_sh",
        "missing": src + "_missing",
    }

    files_to_expand = {
        "Makefile.am": src + "_makefile_am",
        "Makefile.in": src + "_makefile_in",
    }

    for filename, label in files_to_copy.items():
        copy_file(
            name = label,
            src = Label(filename),
            out = src + "/" + filename,
            is_executable = (filename == "configure"),
            tags = ["manual"],
        )

    for filename, label in files_to_expand.items():
        expand_template(
            name = label,
            template = Label(filename + ".tmpl"),
            out = src + "/" + filename,
            substitutions = {
                "{{VARIABLES}}": "\n\t".join(subs),
            },
            tags = ["manual"],
        )

    native.filegroup(
        name = src,
        srcs = list(files_to_copy.values()) + list(files_to_expand.values()),
        tags = ["manual"],
    )

    configure_make_attrs = prepare_build_attrs(configure_make_attrs, {
        "MAKEVARS_FILE": "$$INSTALLDIR/makevars.out",
        "SHELLVARS_FILE": "$$INSTALLDIR/shellvars.out",
    })

    build_name = name + "_build"
    configure_make_attrs.update(dict(
        name = build_name,
        lib_source = Label(src),
        out_headers_only = True,
        targets = ["all"],
        out_data_files = [
            "makevars.out",
            "shellvars.out",
        ],
    ))

    configure_make(**configure_make_attrs)

    tests = {
        "makevars": check_makevars,
        "shellvars": check_shellvars,
    }

    create_env_diff_tests(name, build_name, tests, test_attrs)
