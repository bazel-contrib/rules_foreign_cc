def _generate_install_rule_impl(rctx):
    rctx.download_and_extract(
        url = rctx.attr.url,
        stripPrefix = rctx.attr.stripPrefix,
        output = ".",
    )
    text = """workspace(name='{ws_name}')
load("{init_file}", "{init_function}")
{init_expression}
""".format(ws_name = rctx.attr.name,
 init_file = rctx.attr.init_file,
  init_function = rctx.attr.init_function,
  init_expression = rctx.attr.init_expression)

    rctx.file("WORKSPACE", text)
    rctx.file("BUILD", "")

_generate_install_rule = repository_rule(
    local = True,
    implementation = _generate_install_rule_impl,
    attrs = {
        "url": attr.string(mandatory = True),
        "stripPrefix": attr.string(mandatory = False),
        "init_file": attr.string(mandatory = True),
        "init_function": attr.string(mandatory = True),
        "init_expression": attr.string(mandatory = True),
    },
)

def install_ws_dependency(repo_name, url, strip_prefix, init_file, init_function, init_expression = None):
    init_expression = init_expression if init_expression else (init_function + "()")
    _generate_install_rule(
        name = repo_name,
        url = url,
        stripPrefix = strip_prefix,
        init_file = init_file,
        init_function = init_function,
        init_expression = init_expression
    )
