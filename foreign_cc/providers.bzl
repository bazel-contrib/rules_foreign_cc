""" A module containing all public facing providers """

ForeignCcDepsInfo = provider(
    doc = """Provider to pass transitive information about external libraries.""",
    fields = {
        "artifacts": "Depset of ForeignCcArtifactInfo",
    },
)

ForeignCcFacadeInputsInfo = provider(
    doc = """Internal provider carrying direct foreign_cc outputs for facade rules.

This provider is intended for rules like `foreign_cc_library` that need the direct outputs
of a raw foreign_cc producer target without reverse-engineering them from aggregate `CcInfo`.
It should be treated as unstable implementation detail for now.
""",
    fields = {
        "binary_files": "List of direct binary output files",
        "data_dirs": "List of direct data directory outputs",
        "data_files": "List of direct data file outputs",
        "deps_cc_info": "CcInfo representing the producer target's transitive deps only",
        "header_manifest": "Manifest of relative header paths under include_dir, or None",
        "include_dir": "Direct include directory output, or None",
        "interface_libraries": "List of direct interface library output files",
        "shared_libraries": "List of direct shared library output files",
        "static_libraries": "List of direct static library output files",
    },
)

ForeignCcArtifactInfo = provider(
    doc = """Groups information about the external library install directory,
and relative bin, include and lib directories.

Serves to pass transitive information about externally built artifacts up the dependency chain.

Can not be used as a top-level provider.
Instances of ForeignCcArtifactInfo are encapsulated in a depset [ForeignCcDepsInfo::artifacts](#ForeignCcDepsInfo-artifacts).""",
    fields = {
        "bin_dir_name": "Bin directory, relative to install directory",
        "dll_dir_name": "DLL directory, relative to install directory",
        "gen_dir": "Install directory",
        "include_dir_name": "Include directory, relative to install directory",
        "lib_dir_name": "Lib directory, relative to install directory",
    },
)
