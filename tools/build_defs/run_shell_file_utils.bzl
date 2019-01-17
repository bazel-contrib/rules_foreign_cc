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
    actions - actions factory (ctx.actions)
    target_name - name of the current target (ctx.label.name)
"""

def fictive_file_in_genroot(actions, target_name):
    # we need this fictive file in the genroot to get the path of the root in the script
    empty = actions.declare_file("empty_{}.txt".format(target_name))
    return CreatedByScript(
        file = empty,
        script = "##touch## $$EXT_BUILD_ROOT$$/" + empty.path,
    )

""" Copies directory by $EXT_BUILD_ROOT/orig_path into to $EXT_BUILD_ROOT/copy_path.
I.e. a copy of the directory is created under $EXT_BUILD_ROOT/copy_path.
  Attributes:
    actions - actions factory (ctx.actions)
    orig_path - path to the original directory, relative to the build root
    copy_path - target directory, relative to the build root
"""

def copy_directory(actions, orig_path, copy_path):
    dir_copy = actions.declare_directory(copy_path)
    return CreatedByScript(
        file = dir_copy,
        script = "\n".join([
            "##mkdirs## $$EXT_BUILD_ROOT$$/" + dir_copy.path,
            "##copy_dir_contents_to_dir## {} $$EXT_BUILD_ROOT$$/{}".format(
                orig_path,
                dir_copy.path,
            ),
        ]),
    )
