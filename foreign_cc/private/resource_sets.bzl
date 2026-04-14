"""Resource set definitions for build actions"""

load("@bazel_lib//lib:expand_template.bzl", "expand_template")
load("@bazel_lib//lib:resource_sets.bzl", "resource_set_for")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo", "int_flag", "string_flag")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")

_PARALLELISM_OVERCOMMIT_DEFAULT = 2
_PARALLELISM_OVERCOMMIT_SETTING = "parallelism_overcommit"

_DEFAULT_SIZE = "default"
_SIZES = {
    "enormous": {
        "cpu": 16,
        "mem": 2048,
    },
    "large": {
        "cpu": 8,
        "mem": 1024,
    },
    "medium": {
        "cpu": 4,
        "mem": 500,
    },
    "serial": {
        "cpu": 1,
        "fixed_cpu": True,
        "mem": 250,
    },
    "small": {
        "cpu": 2,
        "mem": 250,
    },
    "tiny": {
        "cpu": 1,
        "mem": 250,
    },
}

def _bazelrc_line(name, value):
    return "common --@rules_foreign_cc//foreign_cc/settings:{}={}".format(name, value)

def _is_fixed(cfg, resource):
    return cfg.get("fixed_{}".format(resource), False)

def _setting(size, resource, mode):
    if size == _DEFAULT_SIZE:
        short_name = _DEFAULT_SIZE
    else:
        short_name = "{}_{}".format(size, resource)

    if mode == "key":
        return "_size_config_" + short_name
    elif mode == "label":
        return "//foreign_cc/settings:size_" + short_name
    else:
        fail("unknown mode", mode)

def create_settings():
    """create the settings that configure these functions."""
    settings = {
        _PARALLELISM_OVERCOMMIT_SETTING: {
            "sort_key": (0, 0, 0, ""),
            "value": _PARALLELISM_OVERCOMMIT_DEFAULT,
        },
        "size_default": {
            "sort_key": (0, 0, 1, ""),
            "value": _DEFAULT_SIZE,
        },
    }
    int_flag(
        name = _PARALLELISM_OVERCOMMIT_SETTING,
        build_setting_default = _PARALLELISM_OVERCOMMIT_DEFAULT,
        visibility = ["//visibility:public"],
    )
    string_flag(
        name = "size_default",
        build_setting_default = _DEFAULT_SIZE,
        values = _SIZES.keys() + [_DEFAULT_SIZE],
        visibility = ["//visibility:public"],
    )

    for size, cfg in _SIZES.items():
        if not cfg:
            fail("invalid size cfg", size)

        for resource in ["cpu", "mem"]:
            if _is_fixed(cfg, resource):
                continue

            name = "size_{}_{}".format(size, resource)
            default = cfg[resource]
            int_flag(
                name = name,
                build_setting_default = default,
                visibility = ["//visibility:public"],
            )

            # Keep the generated bazelrc grouped by descending size, with
            # fixed-resource variants after non-fixed ones when values tie.
            settings[name] = {
                "sort_key": (
                    1,
                    -cfg["cpu"],
                    -cfg["mem"],
                    1 if cfg.get("fixed_cpu", False) or cfg.get("fixed_mem", False) else 0,
                    size,
                    0 if resource == "cpu" else 1,
                ),
                "value": default,
            }

    expand_template(
        name = "settings_script",
        out = "settings.sh",
        template = Label(":settings.sh.in"),
        substitutions = {
            "{{SETTINGS_BAZELRC_LINES}}": "\n".join([
                _bazelrc_line(name, settings[name]["value"])
                for name in sorted(settings.keys(), key = lambda name: settings[name]["sort_key"])
            ]),
        },
    )

    # Create an executable shim for the script
    sh_binary(
        name = "settings",
        srcs = [":settings_script"],
        visibility = ["//visibility:public"],
    )

SIZE_ATTRIBUTES = {
    "resource_size": attr.string(
        values = _SIZES.keys() + [_DEFAULT_SIZE],
        default = _DEFAULT_SIZE,
        mandatory = False,
        doc = """\
Set the approximate size of this build, which controls two things:

1. The Bazel scheduler reservation, so large builds don't all run at once.
2. The parallelism passed to the underlying build system via environment
   variables (CMAKE_BUILD_PARALLEL_LEVEL, GNUMAKEFLAGS, NINJA_JOBS, etc.).

Build tool parallelism is set to the scheduler reservation plus a small
overcommit (default +2, matching ninja's ncpus+2 convention). This hides
I/O latency and lets configure_make targets — whose configure phase is
always serial — make better use of their allocation during the parallel
make phase. The overcommit can be tuned with
@rules_foreign_cc//foreign_cc/settings:parallelism_overcommit.

Each size maps to a cpu and mem value that can be overridden per-size.
See @rules_foreign_cc//foreign_cc/settings:size_{size}_{cpu|mem}, or run
`bazel run @rules_foreign_cc//foreign_cc/settings` to print all settings
in bazelrc format.

The `serial` size is special: it fixes cpu=1 with no overcommit, for
packages that are known-broken under parallel builds.
""",
    ),
    "_parallelism_overcommit": attr.label(
        default = "//foreign_cc/settings:" + _PARALLELISM_OVERCOMMIT_SETTING,
        providers = [BuildSettingInfo],
    ),
} | {
    _setting(size = size, resource = resource, mode = "key"): attr.label(
        default = _setting(size, resource, mode = "label"),
        providers = [BuildSettingInfo],
    )
    for size, cfg in _SIZES.items()
    for resource in ["cpu", "mem"]
    if not _is_fixed(cfg, resource)
} | {
    _setting(size = _DEFAULT_SIZE, resource = None, mode = "key"): attr.label(
        default = _setting(size = _DEFAULT_SIZE, resource = None, mode = "label"),
        providers = [BuildSettingInfo],
    ),
}

def _get_size_config(attr, size, resource):
    name = _setting(size = size, resource = resource, mode = "key")
    s = getattr(attr, name, None)

    if s == None:
        fail("unknown size:", size)

    return s[BuildSettingInfo].value

def get_resource_set(attr):
    """ get the resource set as configured by the settings and attrs

    Args:
        attr: the ctx.attr associated with the target
    Returns:
        A struct with:
            - resource_set: the resource_set callback, or None if bazel default
            - cpu: cpu_cores, or 0 if bazel default
            - mem: mem in MB, or 0 if bazel default
            - allow_cpu_overcommit: True if the build tool may use more
              parallelism than the scheduler reservation (False for sizes
              like "serial" that must enforce an exact -j value)
    """
    size = _DEFAULT_SIZE
    if attr.resource_size != _DEFAULT_SIZE:
        size = attr.resource_size
    else:
        size = _get_size_config(attr, _DEFAULT_SIZE, None)

    if size == _DEFAULT_SIZE:
        return struct(
            resource_set = None,
            cpu = 0,
            mem = 0,
            allow_cpu_overcommit = False,
        )

    cfg = _SIZES[size]
    cpu_value = cfg["cpu"] if _is_fixed(cfg, "cpu") else _get_size_config(attr, size, "cpu")
    mem_value = cfg["mem"] if _is_fixed(cfg, "mem") else _get_size_config(attr, size, "mem")

    if cpu_value < 0:
        fail("cpu must be >= 0")

    if mem_value < 0:
        fail("mem must be >= 0")

    resource_set = resource_set_for(
        cpu_cores = cpu_value,
        mem_mb = mem_value,
    )

    if resource_set:
        actual_resources = resource_set("", "")
        actual_cpu = actual_resources.get("cpu", 0)
        actual_mem = actual_resources.get("memory", 0)
    else:
        actual_cpu = 0
        actual_mem = 0

    return struct(
        resource_set = resource_set,
        cpu = actual_cpu,
        mem = actual_mem,
        allow_cpu_overcommit = not _is_fixed(cfg, "cpu"),
    )

def get_resource_env_vars(attr):
    """ get the values of env vars controlling parallelism

    Because any of these tools (cmake, meson, ninja, make, etc) can call into
    other tools, we set all of the flags in the hopes that complicated call
    structures will still see the values.

    Args:
        attr: the ctx.attr associated with the target
    Returns:
        tuple[resource_set | None, env_vars | None]

        Where resource_set is the correct resource set, and env_vars is the
        dict[str, str] to pass to run/run_shell
    """

    resources = get_resource_set(attr)

    env = None
    if resources.cpu > 0:
        overcommit = attr._parallelism_overcommit[BuildSettingInfo].value if resources.allow_cpu_overcommit else 0
        parallelism = str(resources.cpu + overcommit)
        env = {
            "CMAKE_BUILD_PARALLEL_LEVEL": parallelism,

            # we set GNUMAKEFLAGS instead of MAKEFLAGS because nmake sees
            # MAKEFLAGS but doesn't accept a -j argument, and we don't have a
            # good way of being sure that nmake isn't going to be used as part
            # of a build.
            "GNUMAKEFLAGS": "-j" + parallelism,

            # Meson starts to honor this as of 1.7.0; before that, it only uses
            # ninja's parallelization controls.
            "MESON_NUM_PROCESSES": parallelism,

            # Note that ninja does not honor this by default; it's our wrapper
            # script that handles this.
            # https://github.com/ninja-build/ninja/issues/1482
            "NINJA_JOBS": parallelism,
        }

    return resources.resource_set, env
