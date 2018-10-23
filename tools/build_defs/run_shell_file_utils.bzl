CreatedByScript = provider(
    doc = "Structure to keep declared file or directory and creating script.",
    fields = dict(
        file = "Declared file or directory",
        script = "Script that creates that file or directory",
    ),
)

""" Creates a fictive file under the build root.
This gives the possibility to address the build root in script and construct paths under it.
  Attributes:
    ctx - rule context
"""
def fictive_file_in_genroot(ctx):
    # we need this fictive file in the genroot to get the path of the root in the script
    empty = ctx.actions.declare_file("empty_{}.txt".format(ctx.label.name))
    return CreatedByScript(
        file = empty,
        script = "touch $EXT_BUILD_ROOT/" + empty.path,
    )

""" Copies directory by $EXT_BUILD_ROOT/orig_path into to $EXT_BUILD_ROOT/copy_path.
I.e. a copy of teh directory is created under $EXT_BUILD_ROOT/copy_path.
  Attributes:
    ctx - rule context
    orig_path - path to the original directory, relative to the build root
    copy_path - target directory, relative to the build root
"""

def copy_directory(ctx, orig_path, copy_path):
    dir_copy = ctx.actions.declare_directory(copy_path)
    return CreatedByScript(
        file = dir_copy,
        script = "\n".join([
            "mkdir -p $EXT_BUILD_ROOT/" + dir_copy.path,
            "cp -L -r --no-target-directory {} $EXT_BUILD_ROOT/{}".format(
                orig_path,
                dir_copy.path,
            ),
        ]),
    )
