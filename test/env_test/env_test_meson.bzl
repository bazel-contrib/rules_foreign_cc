"""Macro to test the environment of a meson build."""

load("@bazel_lib//lib:expand_template.bzl", "expand_template")
load("//foreign_cc:meson.bzl", "meson")
load(":utils.bzl", "create_env_diff_tests", "normalize_checked_vars", "prepare_build_attrs")

def env_test_meson(name, *, check_shellvars = None, check_paths = None, meson_attrs = None, test_attrs = None):
    """Macro to test the environment of a meson build

    Args:
        name: str
            prefix to base all the other names on

        check_shellvars: dict[str, str]:
            The shellvars to check, and their expected values.

        check_paths: list[str]:
            Shellvars whose value must name an existing path, checked from
            inside the build as `<VAR>_EXISTS=1`. For values that differ per
            platform or lane, where an exact expectation is impossible.

        meson_attrs: dict[*, *]:
            additional attrs to pass to the meson() rule

        test_attrs: dict[*, *]:
            additional attrs to pass to the diff_test rule
    """
    name = name + "_env_test"

    check_shellvars = normalize_checked_vars("check_shellvars", check_shellvars)
    check_paths = check_paths or []

    # Key -> shell expression for its value. The output must come out sorted
    # by key, like the expected file, so both kinds go through one sorted pass.
    expressions = {shellvar: "$${" + shellvar + "}" for shellvar in check_shellvars}
    for shellvar in check_paths:
        expressions[shellvar + "_EXISTS"] = "$$(test -e \"$${" + shellvar + "}\" && echo 1 || echo 0)"
    check_shellvars = check_shellvars | {shellvar + "_EXISTS": "1" for shellvar in check_paths}

    meson_build = name + "_src"
    subs = []
    for key in sorted(expressions):
        subs.append(
            "run_command('sh', '-c', 'printf \"%s=%s\\\\n\" \"" + key + "\" \"" + expressions[key] + "\" >> \"$$SHELLVARS_FILE\"', check: true)",
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
