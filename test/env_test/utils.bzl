"""Shared helpers for env_test macros."""

load("@bazel_lib//lib:diff_test.bzl", "diff_test")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

# buildifier: disable=function-docstring
def _validate_not_configurable_dict(name, value):
    # These attributes are intentionally non-configurable in these test macros.
    if type(value) != "dict":
        fail("{} must be a dict and is not configurable".format(name))

# buildifier: disable=function-docstring
def normalize_checked_vars(primary_name, primary, secondary_name, secondary):
    if primary and secondary == None:
        secondary = primary

    primary = primary or {}
    secondary = secondary or {}

    _validate_not_configurable_dict(primary_name, primary)
    _validate_not_configurable_dict(secondary_name, secondary)

    return primary, secondary

# buildifier: disable=function-docstring
def prepare_build_attrs(attrs, env_updates):
    attrs = dict(attrs or {})
    tags = list(attrs.get("tags", []))
    tags.append("manual")
    attrs["tags"] = tags

    env = dict(attrs.get("env", {}))
    env.update(env_updates)
    attrs["env"] = env

    return attrs

# buildifier: disable=function-docstring
def create_env_diff_tests(name, build_name, tests, test_attrs):
    test_attrs = test_attrs or {}
    test_attrs.setdefault("size", "small")

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
                "{}={}".format(k, v[k])
                for k in sorted(v.keys())
            ] + [""],
            tags = ["manual"],
        )

        diff_test(
            name = name + "_" + n + "_check",
            file1 = Label(expected),
            file2 = Label(actual),
            **test_attrs
        )
