def _provider_text(symbols):
    return """
WRAPPER = provider(
  doc = "Wrapper to hold imported methods",
  fields = [{}]
)
""".format(", ".join(["\"%s\"" % symbol_ for symbol_ in symbols]))

def _getter_text():
    return """
def id_from_file(file_name):
    (before, middle, after) = file_name.partition(".")
    return before

def get(file_name):
    id = id_from_file(file_name)
    return WRAPPER(**_MAPPING[id])
"""

def _mapping_text(ids):
    data_ = []
    for id in ids:
        data_.append("{id} = wrapper_{id}".format(id = id))
    return "_MAPPING = dict(\n{data}\n)".format(data = ",\n".join(data_))

def _load_and_wrapper_text(id, file_path, symbols):
    load_list = ", ".join(["{id}_{symbol} = \"{symbol}\"".format(id = id, symbol = symbol_) for symbol_ in symbols])
    load_statement = "load(\":{file}\", {list})".format(file = file_path, list = load_list)
    data = ", ".join(["{symbol} = {id}_{symbol}".format(id = id, symbol = symbol_) for symbol_ in symbols])
    wrapper_statement = "wrapper_{id} = dict({data})".format(id = id, data = data)
    return struct(
        load_ = load_statement,
        wrapper = wrapper_statement,
    )

def id_from_file(file_name):
    (before, middle, after) = file_name.partition(".")
    return before

def get_file_name(file_label):
    (before, separator, after) = file_label.partition(":")
    return id_from_file(after)

def _copy_file(rctx, src):
    src_path = rctx.path(src)
    copy_path = src_path.basename
    rctx.template(copy_path, src_path)
    return copy_path

def _generate_overloads(rctx):
    symbols = rctx.attr.symbols
    ids = []
    lines = ["# Generated overload mappings"]
    loads = []
    wrappers = []
    for file_ in rctx.attr.files:
        id = id_from_file(file_.name)
        ids.append(id)
        copy = _copy_file(rctx, file_)
        load_and_wrapper = _load_and_wrapper_text(id, copy, symbols)
        loads.append(load_and_wrapper.load_)
        wrappers.append(load_and_wrapper.wrapper)
    lines += loads
    lines += wrappers
    lines.append(_mapping_text(ids))
    lines.append(_provider_text(symbols))
    lines.append(_getter_text())

    rctx.file("toolchain_data_defs.bzl", "\n".join(lines))
    rctx.file("BUILD", "")

generate_overloads = repository_rule(
    implementation = _generate_overloads,
    attrs = {
        "symbols": attr.string_list(),
        "files": attr.label_list(),
    },
)
