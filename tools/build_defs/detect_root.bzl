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

"""When the directories are also passed in the filegroup with the sources,
we get into a situation when we have containing in the sources list,
which is not allowed by Bazel (execroot creation code fails).
The parent directories will be created for us in the execroot anyway,
so we filter them out."""

def filter_containing_dirs_from_inputs(input_files_list):
    # This puts directories in front of their children in list
    sorted_list = sorted(input_files_list)
    contains_map = {}
    for input in input_files_list:
        # If the immediate parent directory is already in the list, remove it
        if contains_map.get(input.dirname):
            contains_map.pop(input.dirname)
        contains_map[input.path] = input
    return contains_map.values()
