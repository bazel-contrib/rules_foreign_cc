# TODO: This should not be necessary but there appears to be some inconsistent
# behavior with the use of `constraint_value`s in `select` statements. A support
# thread was started at the end of https://github.com/bazelbuild/bazel/pull/12071
# Once it is possible to replace `:windows` with `@platforms//os:windows` that
# should be done for this file. Note actioning on this will set the minimum
# supported version of Bazel to 4.0.0 for these examples.
config_setting(
    name = "windows",
    constraint_values = ["@platforms//os:windows"],
    visibility = ["//visibility:public"],
)

config_setting(
    name = "macos",
    constraint_values = ["@platforms//os:macos"],
    visibility = ["//visibility:public"],
)
