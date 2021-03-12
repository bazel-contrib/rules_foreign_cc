""" A module containing all public facing providers """

# buildifier: disable=name-conventions
ForeignCcDeps = provider(
    doc = """Provider to pass transitive information about external libraries.""",
    fields = {"artifacts": "Depset of ForeignCcArtifact"},
)

# buildifier: disable=name-conventions
ForeignCcArtifact = provider(
    doc = """Groups information about the external library install directory,
and relative bin, include and lib directories.

Serves to pass transitive information about externally built artifacts up the dependency chain.

Can not be used as a top-level provider.
Instances of ForeignCcArtifact are incapsulated in a depset ForeignCcDeps#artifacts.""",
    fields = {
        "bin_dir_name": "Bin directory, relative to install directory",
        "gen_dir": "Install directory",
        "include_dir_name": "Include directory, relative to install directory",
        "lib_dir_name": "Lib directory, relative to install directory",
    },
)
