"""Facade rules that expose raw foreign_cc producer targets with cc_*-like semantics."""

load(
    "//foreign_cc/private:facade_rules.bzl",
    _foreign_cc_binary = "foreign_cc_binary",
    _foreign_cc_import = "foreign_cc_import",
    _foreign_cc_library = "foreign_cc_library",
    _foreign_cc_shared_library = "foreign_cc_shared_library",
    _foreign_cc_static_library = "foreign_cc_static_library",
)

foreign_cc_binary = _foreign_cc_binary
foreign_cc_import = _foreign_cc_import
foreign_cc_library = _foreign_cc_library
foreign_cc_shared_library = _foreign_cc_shared_library
foreign_cc_static_library = _foreign_cc_static_library
