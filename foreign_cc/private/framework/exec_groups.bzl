"""Execution groups shared by foreign builds and their toolchains."""

FOREIGN_CC_EXEC_GROUP = "foreign_cc"

def foreign_cc_exec_groups(toolchains):
    """Resolve all tools used by a foreign build on one execution platform.

    Args:
        toolchains: Toolchain types required by the build action.

    Returns:
        dict: Execution groups for the rule.
    """
    return {FOREIGN_CC_EXEC_GROUP: exec_group(toolchains = toolchains)}

def get_toolchains(ctx):
    """Get the foreign build's toolchains, or the rule's for other callers.

    Args:
        ctx: The rule context.

    Returns:
        ToolchainContext: Toolchains resolved for the build's execution platform.
    """
    if FOREIGN_CC_EXEC_GROUP in ctx.exec_groups:
        return ctx.exec_groups[FOREIGN_CC_EXEC_GROUP].toolchains
    return ctx.toolchains
