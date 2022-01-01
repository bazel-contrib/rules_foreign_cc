"""Entry point for extensions used by bzlmod."""

load("//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")

def _init(module_ctx):
    rules_foreign_cc_dependencies(register_toolchains = False, register_preinstalled_tools = False)

ext = module_extension(implementation = _init)
