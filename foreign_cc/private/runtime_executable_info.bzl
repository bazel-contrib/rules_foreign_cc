"""Private provider for foreign_cc runtime executable adapters."""

ForeignCcRuntimeExecutableInfo = provider(
    doc = "Private provider exposing declared foreign_cc runtime files for executable adapters.",
    fields = {
        "binaries": "Dictionary mapping exact out_binaries entries to declared binary Files.",
        "runtime_files": "Depset of declared foreign_cc outputs needed at runtime.",
    },
)
