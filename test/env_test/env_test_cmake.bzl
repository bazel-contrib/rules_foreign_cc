"""Macro to test the environment of a cmake build."""

load("@bazel_lib//lib:expand_template.bzl", "expand_template")
load("//foreign_cc:cmake.bzl", "cmake")
load(":utils.bzl", "create_env_diff_tests", "normalize_checked_vars", "prepare_build_attrs")

def env_test_cmake(name, *, check_cmakevars = None, check_shellvars = None, cmake_attrs = None, test_attrs = None):
    """Macro to test the environment of a cmake build

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

    check_cmakevars = normalize_checked_vars("check_cmakevars", check_cmakevars)
    check_shellvars = normalize_checked_vars("check_shellvars", check_shellvars, default = check_cmakevars)

    cmakelists = name + "_src"
    subs = []
    for cmakevar in sorted(check_cmakevars):
        subs.append(
            "file(APPEND \"$$ENV{{CMAKEVARS_FILE}}\" \"{v}=$${{{v}}}\\n\")".format(v = cmakevar),
        )

    for shellvar in sorted(check_shellvars):
        subs.append(
            "file(APPEND \"$$ENV{{SHELLVARS_FILE}}\" \"{v}=$$ENV{{{v}}}\\n\")".format(v = shellvar),
        )

    expand_template(
        name = cmakelists,
        template = Label(":CMakeLists.txt.tmpl"),
        out = cmakelists + "/CMakeLists.txt",
        substitutions = {
            "{{VARIABLES}}": "\n".join(subs),
        },
        tags = ["manual"],
    )

    cmake_attrs = prepare_build_attrs(cmake_attrs, {
        "CMAKEVARS_FILE": "$$INSTALLDIR/cmakevars.out",
        "SHELLVARS_FILE": "$$INSTALLDIR/shellvars.out",
    })

    build_name = name + "_build"
    cmake_attrs.update(dict(
        name = build_name,
        lib_source = Label(cmakelists),
        install = False,
        out_include_dir = "",
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

    create_env_diff_tests(name, build_name, tests, test_attrs)
