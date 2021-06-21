<!-- Generated with Stardoc: http://skydoc.bazel.build -->

 A module containing all public facing providers 

<a id="#ForeignCcArtifactInfo"></a>

## ForeignCcArtifactInfo

<pre>
ForeignCcArtifactInfo(<a href="#ForeignCcArtifactInfo-bin_dir_name">bin_dir_name</a>, <a href="#ForeignCcArtifactInfo-gen_dir">gen_dir</a>, <a href="#ForeignCcArtifactInfo-include_dir_name">include_dir_name</a>, <a href="#ForeignCcArtifactInfo-lib_dir_name">lib_dir_name</a>)
</pre>

Groups information about the external library install directory,
and relative bin, include and lib directories.

Serves to pass transitive information about externally built artifacts up the dependency chain.

Can not be used as a top-level provider.
Instances of ForeignCcArtifactInfo are encapsulated in a depset [ForeignCcDepsInfo::artifacts](#ForeignCcDepsInfo-artifacts).

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="ForeignCcArtifactInfo-bin_dir_name"></a>bin_dir_name |  Bin directory, relative to install directory    |
| <a id="ForeignCcArtifactInfo-gen_dir"></a>gen_dir |  Install directory    |
| <a id="ForeignCcArtifactInfo-include_dir_name"></a>include_dir_name |  Include directory, relative to install directory    |
| <a id="ForeignCcArtifactInfo-lib_dir_name"></a>lib_dir_name |  Lib directory, relative to install directory    |


<a id="#ForeignCcDepsInfo"></a>

## ForeignCcDepsInfo

<pre>
ForeignCcDepsInfo(<a href="#ForeignCcDepsInfo-artifacts">artifacts</a>)
</pre>

Provider to pass transitive information about external libraries.

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="ForeignCcDepsInfo-artifacts"></a>artifacts |  Depset of ForeignCcArtifactInfo    |


