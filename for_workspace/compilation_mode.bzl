def _compilation_mode(ctx):
    return [config_common.FeatureFlagInfo(value = str(ctx.attr.is_debug))]

compilation_mode = rule(
    attrs = {
        "is_debug": attr.bool(),
    },
    implementation = _compilation_mode,
)
