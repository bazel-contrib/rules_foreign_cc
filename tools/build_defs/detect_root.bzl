def detect_root(source):
    """Detects the path to the topmost directory of the 'source' outputs.
    To be used with external build systems to point to the source code/tools directories.
"""

    root = ""
    sources = source.files.to_list()
    if (root and len(root) > 0) or len(sources) == 0:
        return root

    root = ""
    level = -1
    num_at_level = 0

    # find topmost directory
    for file in sources:
        file_level = _get_level(file.path)
        if level == -1 or level > file_level:
            root = file.path
            level = file_level
            num_at_level = 1
        elif level == file_level:
            num_at_level += 1

    if num_at_level == 1:
        return root

    (before, sep, after) = root.rpartition("/")
    if before and sep and after:
        return before
    return root

def _get_level(path):
    normalized = path
    for i in range(len(path)):
        new_normalized = normalized.replace("//", "/")
        if len(new_normalized) == len(normalized):
            break
        normalized = new_normalized

    return normalized.count("/")
