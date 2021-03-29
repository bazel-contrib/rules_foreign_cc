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

    # find topmost directory
    root = None
    for file in sources:
        if root == None or root.startswith(file.dirname):
            root = file.dirname

    if not root:
        fail("No root source or directory was found")

    return root

# buildifier: disable=function-docstring-header
# buildifier: disable=function-docstring-args
# buildifier: disable=function-docstring-return
def filter_containing_dirs_from_inputs(input_files_list):
    """When the directories are also passed in the filegroup with the sources,
    we get into a situation when we have containing in the sources list,
    which is not allowed by Bazel (execroot creation code fails).
    The parent directories will be created for us in the execroot anyway,
    so we filter them out."""

    populated_dirs = {f.dirname: None for f in input_files_list}
    return [f for f in input_files_list if f.path not in populated_dirs]
    