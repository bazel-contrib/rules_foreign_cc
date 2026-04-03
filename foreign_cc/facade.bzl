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
foreign_cc_static_library = _foreign_cc_static_library

def foreign_cc_shared_library(**kwargs):
    """Public shared-library facade with package-relative exports_filter canonicalization.

    Args:
      **kwargs: Forwarded shared-facade arguments. `exports_filter` entries are
        canonicalized relative to the calling package before delegation.
    """
    exports_filter = kwargs.get("exports_filter")
    if type(exports_filter) == type([]):
        canonical_exports_filter = []
        for export_filter in exports_filter:
            if (
                export_filter == "__pkg__" or
                export_filter == "__subpackages__" or
                export_filter.endswith(":__pkg__") or
                export_filter.endswith(":__subpackages__")
            ):
                fail("`foreign_cc_shared_library(exports_filter = ...)` currently supports explicit labels only; wildcard filters like `{}` are not yet implemented".format(export_filter))
            canonical_exports_filter.append(str(native.package_relative_label(export_filter)))
        kwargs["exports_filter"] = canonical_exports_filter
    _foreign_cc_shared_library(**kwargs)
