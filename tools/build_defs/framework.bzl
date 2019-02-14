""" Contains definitions for creation of external C/C++ build rules (for building external libraries
 with CMake, configure/make, autotools).
 Due to the changes in Bazel Starlark API loads the correct version of implementation
 and re-exports them.
"""

load(
    "@foreign_cc_impl//:framework.bzl",
    impl_CC_EXTERNAL_RULE_ATTRIBUTES = "CC_EXTERNAL_RULE_ATTRIBUTES",
    impl_ForeignCcArtifact = "ForeignCcArtifact",
    impl_ForeignCcDeps = "ForeignCcDeps",
    impl_cc_external_rule_impl = "cc_external_rule_impl",
    impl_create_attrs = "create_attrs",
    impl_get_foreign_cc_dep = "get_foreign_cc_dep",
)

CC_EXTERNAL_RULE_ATTRIBUTES = impl_CC_EXTERNAL_RULE_ATTRIBUTES
ForeignCcArtifact = impl_ForeignCcArtifact
ForeignCcDeps = impl_ForeignCcDeps
cc_external_rule_impl = impl_cc_external_rule_impl
create_attrs = impl_create_attrs
get_foreign_cc_dep = impl_get_foreign_cc_dep
