"""A helper module to inform users this package is deprecated"""

def print_deprecation():
    # buildifier: disable=print
    print(
        "`@rules_foreign_cc//for_workspace/...` is deprecated, please " +
        "find the relevant symbols in `@rules_foreign_cc//foreign_cc/built_tools/...`. " +
        "Note that the core rules can now be loaded from " +
        "`@rules_foreign_cc//foreign_cc:defs.bzl`",
    )
