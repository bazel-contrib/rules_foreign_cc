"""Shared helpers for env_test macros."""

load("@bazel_lib//lib:diff_test.bzl", "diff_test")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

# buildifier: disable=function-docstring
def normalize_checked_vars(name, value, default = None):
    if value == None:
        value = default

    if value == None:
        value = {}

    if type(value) != "dict":
        fail("{} must be a dict and is not configurable".format(name))

    return value

# buildifier: disable=function-docstring
def prepare_build_attrs(attrs, env_updates):
    attrs = dict(attrs or {})
    tags = list(attrs.get("tags", []))
    if "manual" not in tags:
        tags.append("manual")
    attrs["tags"] = tags

    env = dict(attrs.get("env", {}))
    env.update(env_updates)
    attrs["env"] = env

    return attrs

# buildifier: disable=function-docstring
def create_env_diff_tests(name, build_name, tests, test_attrs):
    test_attrs = dict(test_attrs or {})
    test_attrs.setdefault("size", "small")

    for test_name, expected_vars in tests.items():
        if not expected_vars:
            continue

        actual = name + "_" + test_name + "_actual"
        native.filegroup(
            name = actual,
            srcs = [build_name],
            output_group = test_name + ".out",
            tags = ["manual"],
        )

        expected = name + "_" + test_name + "_expected"
        write_file(
            name = expected,
            out = expected + ".out",
            content = [
                "{}={}".format(k, expected_vars[k])
                for k in sorted(expected_vars)
            ] + [""],
            tags = ["manual"],
        )

        diff_test(
            name = name + "_" + test_name + "_check",
            file1 = Label(expected),
            file2 = Label(actual),
            **test_attrs
        )
