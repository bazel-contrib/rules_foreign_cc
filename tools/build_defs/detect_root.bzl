def detect_root(source):
    """Detects the path to the topmost directory of the 'source' outputs.
    To be used with external build systems to point to the source code/tools directories.
"""

    root = ""
    sources = source.files.to_list()

    if len(sources) == 0:
        return root

    # is there a predefined maxint?
    level = 999

    # find topmost directory
    for file in sources:
        file_level = _get_level(file.dirname)
        if level > file_level:
            root = file.dirname
            level = file_level

    return root

def _get_level(path):
    normalized = path
    for i in range(len(path)):
        new_normalized = normalized.replace("//", "/")
        if len(new_normalized) == len(normalized):
            break
        normalized = new_normalized

    return normalized.count("/")
