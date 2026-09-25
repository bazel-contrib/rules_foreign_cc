"""Helpers for sizing rules_foreign_cc build actions on a remote executor.

Bazel's `resource_set` is read by the local execution scheduler only. A remote
executor sizes an action from the RE platform properties attached to it, and
nothing in the Starlark action API can set those. What a ruleset *can* do is
put each action in a named exec group, because `exec_properties` -- on a
`platform()` or on a target -- can be scoped to one:

    exec_properties = {"<exec group>.<key>": "<value>"}

rules_foreign_cc runs each build action in the exec group named after its
`resource_size`, so a remote user declares the mapping once on their platform
and every sized target picks it up.

The property *keys* are executor-specific (BuildBuddy spells them
`EstimatedCPU`/`EstimatedMemory`, Buildfarm `min-cores`/`min-mem`, and others
differ again), so this helper takes them as arguments rather than guessing.
"""

load(
    "//foreign_cc/private:resource_sets.bzl",
    _SIZES = "SIZES",
    _size_exec_group_name = "size_exec_group_name",
)

def foreign_cc_size_exec_properties(
        cpu_property = None,
        memory_property = None,
        memory_format = "{}",
        sizes = None):
    """Builds the `exec_properties` describing every `resource_size` to a remote executor.

    Example, for a BuildBuddy-style executor:

        platform(
            name = "rbe_linux",
            exec_properties = foreign_cc_size_exec_properties(
                cpu_property = "EstimatedCPU",
                memory_property = "EstimatedMemory",
                memory_format = "{}M",
            ) | {"container-image": "docker://..."},
        )

    Args:
      cpu_property: property name for the cpu request, or None to omit it.
      memory_property: property name for the memory request, or None to omit it.
      memory_format: format string applied to the memory value, which is in MB.
        Use e.g. `"{}M"` or `"{}MB"` for executors that require a unit suffix.
      sizes: optional `{size: struct(cpu, mem)}` overriding the built-in table.
        Pass this if you have overridden the `size_<size>_<cpu|mem>` build
        settings; this helper runs at load time and cannot read them.

    Returns:
      dict[str, str] suitable for a `platform()`'s or a target's `exec_properties`.
    """
    if not cpu_property and not memory_property:
        fail("foreign_cc_size_exec_properties: set cpu_property, memory_property, or both")

    properties = {}
    for size, cfg in (sizes or _SIZES).items():
        prefix = _size_exec_group_name(size) + "."
        if cpu_property:
            properties[prefix + cpu_property] = str(cfg.cpu)
        if memory_property:
            properties[prefix + memory_property] = memory_format.format(cfg.mem)

    return properties
