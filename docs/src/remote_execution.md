# Remote execution

A `rules_foreign_cc` target runs a whole nested build — make, ninja, b2 — inside a single Bazel
action. Telling the scheduler how big that action is matters more here than for an ordinary
compile, and it has to be told twice, because local and remote execution read entirely different
things.

## What `resource_size` already does

Setting [`resource_size`](rules.md) on a target does two things today:

1. Attaches a `resource_set` to the action, which Bazel's **local** scheduler uses to reserve cpu
   and memory instead of assuming roughly one core.
2. Puts the same job count in the action's environment (`CMAKE_BUILD_PARALLEL_LEVEL`,
   `GNUMAKEFLAGS`, `MESON_NUM_PROCESSES`, `NINJA_JOBS`) or on the build tool's command line
   (b2's `-j`), so the nested build uses the parallelism Bazel budgeted rather than the machine's
   full core count.

Point 2 works on a remote executor already — the environment travels with the action. Point 1 does
not: `resource_set` is a local-scheduler concept. A remote executor sizes an action from the
[RE platform properties](https://github.com/bazelbuild/remote-apis) attached to it.

## What the exec groups add

Starlark has no way to attach platform properties to an individual action — `ctx.actions.run_shell`
has no `exec_properties` parameter, and an action's `execution_requirements` are not forwarded to
the remote platform. The one mechanism a ruleset can use is
[execution groups](https://bazel.build/extending/exec-groups): `exec_properties` on a `platform()`
or on a target can be scoped to a named group.

So every `rules_foreign_cc` build action runs in the exec group named after its `resource_size`:

| `resource_size` | exec group     |
| --------------- | -------------- |
| `tiny`          | `size_tiny`    |
| `small`         | `size_small`   |
| `medium`        | `size_medium`  |
| `large`         | `size_large`   |
| `enormous`      | `size_enormous`|
| `serial`        | `size_serial`  |
| `default`       | *(the default exec group — no routing)* |

You declare the sizing once, on your platform, and every sized target picks it up:

```python
platform(
    name = "rbe_linux",
    exec_properties = {
        "container-image": "docker://...",
        "size_large.EstimatedCPU": "8",
        "size_large.EstimatedMemory": "1024M",
        "size_enormous.EstimatedCPU": "16",
        "size_enormous.EstimatedMemory": "2048M",
    },
)
```

Property names are executor-specific. BuildBuddy uses `EstimatedCPU` / `EstimatedMemory`;
Buildfarm uses `min-cores` / `max-cores` / `min-mem`; other executors differ again. Check your
executor's documentation for the names and value formats it accepts.

## Generating the properties

Rather than hand-writing one entry per size, `foreign_cc_size_exec_properties` generates the whole
dict from the same size table the rules use:

```python
load("@rules_foreign_cc//foreign_cc:defs.bzl", "foreign_cc_size_exec_properties")

platform(
    name = "rbe_linux",
    exec_properties = foreign_cc_size_exec_properties(
        cpu_property = "EstimatedCPU",
        memory_property = "EstimatedMemory",
        memory_format = "{}M",
    ) | {"container-image": "docker://..."},
)
```

Either property may be omitted if your executor only schedules on one dimension.

The helper runs at load time, so it cannot read the `size_<size>_<cpu|mem>` build settings. If you
have overridden any of those, pass matching values through the `sizes` argument so the platform
and the scheduler agree:

```python
foreign_cc_size_exec_properties(
    cpu_property = "EstimatedCPU",
    sizes = {
        "large": struct(cpu = 3, mem = 1024),
        # ...
    },
)
```

## Interaction with `exec_compatible_with`

A declared exec group does not inherit a target's `exec_compatible_with`, so routing the build
action into one would silently drop that constraint. Rather than diverge, the rules fail at
analysis time if a target sets both `exec_compatible_with` and a non-default `resource_size`. Use
Bazel's per-group form instead:

```python
cmake(
    name = "foo",
    exec_group_compatible_with = {"size_large": ["@platforms//os:linux"]},
    resource_size = "large",
    # ...
)
```

Or turn the routing off entirely, which restores the previous behavior of running every build
action in the default exec group:

```
common --@rules_foreign_cc//foreign_cc/settings:size_exec_groups=False
```

## Sizing the local scheduler too

The per-size cpu and memory values are build settings, so you can tune them for your machines
without touching any target. Run

```
bazel run @rules_foreign_cc//foreign_cc/settings
```

to print every setting in `bazelrc` form, then copy the ones you want into your own `bazelrc`.
