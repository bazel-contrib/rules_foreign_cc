"""Resource set definitions for build actions"""

load("@bazel_lib//lib:expand_template.bzl", "expand_template")
load("@bazel_lib//lib:resource_sets.bzl", "resource_set_for")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo", "int_flag", "string_flag")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")

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
    settings = {"size_default": _DEFAULT_SIZE}
    string_flag(
        name = "size_default",
        build_setting_default = _DEFAULT_SIZE,
        values = _SIZES.keys() + [_DEFAULT_SIZE],
        visibility = ["//visibility:public"],
    )

    for size, cfg in _SIZES.items():
        if not cfg:
            fail("invalid size cfg", size)

        # keep this in sync with the docs and the above helper!
        cpu_name = "size_{}_cpu".format(size)
        cpu_default = _SIZES[size]["cpu"]
        int_flag(
            name = cpu_name,
            build_setting_default = cpu_default,
            visibility = ["//visibility:public"],
        )
        settings[cpu_name] = cpu_default

        mem_name = "size_{}_mem".format(size)
        mem_default = _SIZES[size]["mem"]
        int_flag(
            name = mem_name,
            build_setting_default = mem_default,
            visibility = ["//visibility:public"],
        )
        settings[mem_name] = mem_default

    expand_template(
        name = "settings_script",
        out = "settings.sh",
        template = Label(":settings.sh.in"),
        substitutions = {
            "{{SETTINGS_BAZELRC_LINES}}": "\n".join([
                _bazelrc_line(name, settings[name])
                for name in sorted(settings.keys())
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
Set the approximate size of this build. This does two things:
1. Sets the environment variables to tell the underlying build system the
   requested parallelization; examples are CMAKE_BUILD_PARALLEL_LEVEL for cmake
   or MAKEFLAGS for autotools.
2. Sets the resource_set attribute on the action to tell bazel how many cores
   are being used, so it schedules appropriately.  The sizes map to labels,
   which can be used to override the meaning of the sizes. See
   @rules_foreign_cc//foreign_cc/settings:size_{size}_{cpu|mem}.

Running `bazel run @rules_foreign_cc//foreign_cc/settings` will print out all
the settings in bazelrc format for easy customization.
""",
    ),
} | {
    _setting(size = size, resource = resource, mode = "key"): attr.label(
        default = _setting(size, resource, mode = "label"),
        providers = [BuildSettingInfo],
    )
    for size in _SIZES.keys()
    for resource in ["cpu", "mem"]
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
        A tuple of:
            - the resource_set, or None if it's the bazel default
            - cpu_cores, or 0 if it's the bazel default
            - mem in MB, or 0 if it's the bazel default
    """
    size = _DEFAULT_SIZE
    if attr.resource_size != _DEFAULT_SIZE:
        size = attr.resource_size
    else:
        size = _get_size_config(attr, _DEFAULT_SIZE, None)

    if size == _DEFAULT_SIZE:
        return None, 0, 0

    cpu_value = _get_size_config(attr, size, "cpu")
    mem_value = _get_size_config(attr, size, "mem")

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

    return resource_set, actual_cpu, actual_mem

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

    resource_set, cpu, _mem = get_resource_set(attr)

    env = None
    if cpu > 0:
        sc = str(cpu)
        env = {
            "CMAKE_BUILD_PARALLEL_LEVEL": sc,

            # we set GNUMAKEFLAGS instead of MAKEFLAGS because nmake sees
            # MAKEFLAGS but doesn't accept a -j argument, and we don't have a
            # good way of being sure that nmake isn't going to be used as part
            # of a build.
            "GNUMAKEFLAGS": "-j" + sc,

            # Meson starts to honor this as of 1.7.0; before that, it only uses
            # ninja's parallelization controls.
            "MESON_NUM_PROCESSES": sc,

            # Note that ninja does not honor this by default; it's our wrapper
            # script that handles this.
            # https://github.com/ninja-build/ninja/issues/1482
            "NINJA_JOBS": sc,
        }

    return resource_set, env
