def _test_binary(ctx):
    # todo: why does it work?
    binary_path = ctx.attr.binary[DefaultInfo].default_runfiles.files.to_list()[0].short_path

    script = [
        "bin_path={binary}".format(binary = binary_path),
        "result_{name}=$($bin_path {args})".format(
            name = ctx.label.name,
            binary = binary_path,
            args = " ".join(ctx.attr.args),
        ),
        "if [[ \"$result_{name}*\" != \"{expected}*\" ]]; then exit -1; fi".format(
            name = ctx.label.name,
            expected = ctx.attr.expected_output,
        ),
    ]

    print("script: " + "\n".join(script))

    ctx.actions.write(
        output = ctx.outputs.executable,
        content = "\n".join(script),
    )

    runfiles = ctx.runfiles(files = ctx.files.binary + ctx.files.data)
    return [DefaultInfo(runfiles = runfiles)]

binary_test = rule(
    implementation = _test_binary,
    attrs = {
        "binary": attr.label(mandatory = True, allow_single_file = True),
        "data": attr.label_list(mandatory = False, default = []),
        "expected_output": attr.string(mandatory = True),
    },
    test = True,
)
