"""DEPRECATED: Please use the sources in `@rules_foreign_cc//foreign_cc/...`"""

# buildifier: disable=bzl-visibility
load(
    "//foreign_cc/private:framework.bzl",
    _CC_EXTERNAL_RULE_ATTRIBUTES = "CC_EXTERNAL_RULE_ATTRIBUTES",
    _ConfigureParameters = "ConfigureParameters",
    _InputFiles = "InputFiles",
    _WrappedOutputs = "WrappedOutputs",
    _cc_external_rule_impl = "cc_external_rule_impl",
    _create_attrs = "create_attrs",
    _get_foreign_cc_dep = "get_foreign_cc_dep",
    _uniq_list_keep_order = "uniq_list_keep_order",
    _wrap_outputs = "wrap_outputs",
)
load("//tools/build_defs:deprecation.bzl", "print_deprecation")

print_deprecation()

CC_EXTERNAL_RULE_ATTRIBUTES = _CC_EXTERNAL_RULE_ATTRIBUTES

cc_external_rule_impl = _cc_external_rule_impl

# buildifier: disable=name-conventions
ConfigureParameters = _ConfigureParameters

create_attrs = _create_attrs

get_foreign_cc_dep = _get_foreign_cc_dep

# buildifier: disable=name-conventions
InputFiles = _InputFiles

uniq_list_keep_order = _uniq_list_keep_order

wrap_outputs = _wrap_outputs

# buildifier: disable=name-conventions
WrappedOutputs = _WrappedOutputs
