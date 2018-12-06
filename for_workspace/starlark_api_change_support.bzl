def has_bazel_cc_info():
    return hasattr(cc_common, "create_compilation_context")

def _generate_implementation_fragments(rctx):
    prefix = ""
    if has_bazel_cc_info():
        bazel_version = native.bazel_version
        if native.bazel_version.startswith("0.20."):
            prefix = "//tools/build_defs/old_11_2018:"
        else:
            prefix = "//tools/build_defs/new_11_2018:"
    else:
        prefix = "//tools/build_defs/old_10_2018:"

    rctx.file("BUILD", "export_files([\"framework.bzl\", \"cc_toolchain_util.bzl\"])")

    for name_ in ["framework.bzl", "cc_toolchain_util.bzl"]:
        path = rctx.path(Label(prefix + name_))
        rctx.template(name_, path)

generate_implementation_fragments = repository_rule(
    implementation = _generate_implementation_fragments,
    attrs = {
        "_deps": attr.label_list(
            default = [
                "@rules_foreign_cc//tools/build_defs/new_11_2018/cc_toolchain_util.bzl",
                "@rules_foreign_cc//tools/build_defs/new_11_2018/framework.bzl",

                "@rules_foreign_cc//tools/build_defs/old_11_2018/cc_toolchain_util.bzl",
                "@rules_foreign_cc//tools/build_defs/old_11_2018/framework.bzl",

                "@rules_foreign_cc//tools/build_defs/old_10_2018/cc_toolchain_util.bzl",
                "@rules_foreign_cc//tools/build_defs/old_10_2018/framework.bzl",
            ]
        ),
    }
)
