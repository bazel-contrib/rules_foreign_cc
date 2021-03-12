# buildifier: disable=module-docstring
# buildifier: disable=function-docstring-header
def detect_root(source):
    """Detects the path to the topmost directory of the 'source' outputs.
    To be used with external build systems to point to the source code/tools directories.

    Args:
        source (Target): A filegroup of source files

    Returns:
        string: The relative path to the root source directory
    """

    sources = source.files.to_list()
    if len(sources) == 0:
        return ""

    root = None
    level = -1

    # find topmost directory
    for file in sources:
        file_level = _get_level(file.path)

        # If there is no level set or the current file's level
        # is greather than what we have logged, update the root
        if level == -1 or level > file_level:
            root = file
            level = file_level

    if not root:
        fail("No root source or directory was found")

    if root.is_source:
        return root.dirname

    # Note this code path will never be hit due to a bug upstream Bazel
    # https://github.com/bazelbuild/bazel/issues/12954

    # If the root is not a source file, it must be a directory.
    # Thus the path is returned
    return root.path

def _get_level(path):
    """Determine the number of sub directories `path` is contained in

    Args:
        path (string): The target path

    Returns:
        int: The directory depth of `path`
    """
    normalized = path

    # This for loop ensures there are no double `//` substrings.
    # A for loop is used because there's not currently a `while`
    # or a better mechanism for guaranteeing all `//` have been
    # cleaned up.
    for i in range(len(path)):
        new_normalized = normalized.replace("//", "/")
        if len(new_normalized) == len(normalized):
            break
        normalized = new_normalized

    return normalized.count("/")

# buildifier: disable=function-docstring-header
# buildifier: disable=function-docstring-args
# buildifier: disable=function-docstring-return
def filter_containing_dirs_from_inputs(input_files_list):
    """When the directories are also passed in the filegroup with the sources,
    we get into a situation when we have containing in the sources list,
    which is not allowed by Bazel (execroot creation code fails).
    The parent directories will be created for us in the execroot anyway,
    so we filter them out."""

    # This puts directories in front of their children in list
    sorted_list = sorted(input_files_list)
    contains_map = {}
    for input in input_files_list:
        # If the immediate parent directory is already in the list, remove it
        if contains_map.get(input.dirname):
            contains_map.pop(input.dirname)
        contains_map[input.path] = input
    return contains_map.values()
