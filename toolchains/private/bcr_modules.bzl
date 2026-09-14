"""Bazel Central Registry modules rules_foreign_cc consumes as external repos.

`make`, `ninja` and `pkgconf` are no longer bootstrapped by rules_foreign_cc.
All three are published on the BCR with a maintained BUILD file that compiles
them as plain `cc_binary` targets against the resolved exec-platform
cc_toolchain, so rfcc just depends on those repos and points a
`native_tool_toolchain` at the binary. A build problem in any of them is then
fixed by patching the BCR module, where the fix is shared with every other
consumer, instead of in a bootstrap script only rfcc runs.

`BCR_TOOLS` is keyed by the module's registry name, which is also the repo name
rfcc gives it under both dependency models. For make and ninja that is the
tool's own name; rfcc's `pkgconfig` tool is the `pkgconf` module, the
pkg-config implementation distributions have shipped as `pkg-config` for years
(its BUILD file publishes the binary under both names).

Each inner dict carries every version of that tool rfcc offers, keyed by the
version of the *tool*. How a caller picks one differs by dependency model:

  * WORKSPACE has no registry client, so `bcr_repos.bzl` fetches whichever
    version `rules_foreign_cc_dependencies(make_version = ...)` named, straight
    from these entries. See that file for the `source.json` mapping.
  * bzlmod resolves `//MODULE.bazel`'s `bazel_dep` to one version graph-wide.
    rfcc pins the newest entry below; a root module that wants another raises
    its own `bazel_dep` or `single_version_override`.

`BCR_CLOSURE` holds the modules those BUILD files need but rfcc never loads
from -- bzlmod resolves them transitively, WORKSPACE needs them listed.

This module is deliberately load-free so the planner and `tool_specs.bzl` can
read the version data without pulling `@bazel_tools`' repository-rule Starlark
into every BUILD file's load graph.
"""

visibility([
    "//foreign_cc/private",
    "//toolchains/private",
])

def _module(
        registry_version,
        urls,
        integrity,
        strip_prefix = "",
        overlay = {},
        patches = {},
        patch_strip = 0):
    """One BCR module version, transcribed from its `source.json`.

    Args:
        registry_version: the version directory under `modules/<name>/` in the
            registry. Usually the tool's own version, but the registry appends
            a `.bcr.N` suffix when it re-releases a module with no upstream
            release behind it (packaging fixes, added patches) -- `4.4.1.bcr.1`
            is still make 4.4.1. Only this field knows the difference; every
            key in `BCR_TOOLS` is the tool version a user names.
        urls: `url` followed by `mirror_urls`.
        integrity: the archive's `integrity`.
        strip_prefix: the archive's `strip_prefix`; omit when it has none.
        overlay: `{path: integrity}`, whole files the registry lays over the
            archive.
        patches: `{filename: integrity}`, patches the registry applies.
        patch_strip: `-p` level for `patches`.

    Returns:
        A struct with those fields.
    """
    return struct(
        registry_version = registry_version,
        urls = urls,
        integrity = integrity,
        strip_prefix = strip_prefix,
        overlay = overlay,
        patches = patches,
        patch_strip = patch_strip,
    )

# Registry module name -> {tool version: the BCR module that builds it}. The
# inner keys are what `tools.<tool>(version = ...)` and
# `rules_foreign_cc_dependencies(<tool>_version = ...)` accept.
BCR_TOOLS = {
    "make": {
        "4.3": _module(
            registry_version = "4.3",
            urls = [
                "https://ftp.gnu.org/gnu/make/make-4.3.tar.gz",
                "https://mirrors.kernel.org/gnu/make/make-4.3.tar.gz",
            ],
            integrity = "sha256-4F/d5HxffKRctpfpc4lP9PXXnhO3UO1X17Ztje/Hjhk=",
            strip_prefix = "make-4.3",
            overlay = {
                "BUILD.bazel": "sha256-ATbafC4BzqInqJ0RO/0MPmnr7rB4zo1+IdL+7QKheOc=",
                "MODULE.bazel": "sha256-lB2S1eQwMDSPBtrYGDaecsIOXU8D2w1vez0GshR+wNQ=",
                "tests/BUILD.bazel": "sha256-jIQPZGpDagYruQa2D4rxsjjwsH9adwZjROvWP8ePm/E=",
                "tests/make_smoke_test.cc": "sha256-iKte4ueLCD0vIG7jakOU+Aq9Cs5IfwLC9d/OuIGQk4I=",
            },
            patches = {
                "msvc-have-umask.patch": "sha256-SQuZEg8IQmRLY60vzavkjKu3ePilCVQC4JF3yJ1GxW8=",
            },
            patch_strip = 1,
        ),
        "4.4": _module(
            registry_version = "4.4",
            urls = [
                "https://ftp.gnu.org/gnu/make/make-4.4.tar.gz",
                "https://mirrors.kernel.org/gnu/make/make-4.4.tar.gz",
            ],
            integrity = "sha256-WB9NToctp0s5Qch0IViYp9NYAvA3Mr3M7h1KeXkQXRg=",
            strip_prefix = "make-4.4",
            overlay = {
                "BUILD.bazel": "sha256-XsWo8qlrrYIEmjkMCVMIMJI2DTO8A1NFTbR0qlo4hkc=",
                "MODULE.bazel": "sha256-nQQYxOOl19LkDFNFPuNkL5aEaGJnVtEosizDnXnsLm8=",
                "tests/BUILD.bazel": "sha256-jIQPZGpDagYruQa2D4rxsjjwsH9adwZjROvWP8ePm/E=",
                "tests/make_smoke_test.cc": "sha256-iKte4ueLCD0vIG7jakOU+Aq9Cs5IfwLC9d/OuIGQk4I=",
            },
            patches = {
                "msvc-have-umask.patch": "sha256-Y8X/WwKvfgERg47rRWLtjYz9SR/1C5PhHju7V3JnFio=",
            },
            patch_strip = 1,
        ),
        "4.4.1": _module(
            registry_version = "4.4.1.bcr.1",
            urls = [
                "https://mirror.bazel.build/ftp.gnu.org/gnu/make/make-4.4.1.tar.gz",
                "https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz",
                "https://mirrors.kernel.org/gnu/make/make-4.4.1.tar.gz",
            ],
            integrity = "sha256-3Rb7HWe/q3mnL16DkHNcSePo5wtJRaFasfgd23hlj7M=",
            strip_prefix = "make-4.4.1",
            overlay = {
                "BUILD.bazel": "sha256-H6pkUq0x1L3UZ4H+4fyYKbZKjN3ou2qbWbgPUftpodk=",
                "MODULE.bazel": "sha256-it4sTy6/xjifgZLQMdVwLoR4AGmglnYaouUCCJ+7MPI=",
                "tests/BUILD.bazel": "sha256-jIQPZGpDagYruQa2D4rxsjjwsH9adwZjROvWP8ePm/E=",
                "tests/make_smoke_test.cc": "sha256-iKte4ueLCD0vIG7jakOU+Aq9Cs5IfwLC9d/OuIGQk4I=",
            },
            patches = {
                "msvc-have-umask.patch": "sha256-SRveI1RrJ0p5t8v7gZ1mJrlKCiPkogHTvhfeE8ak2Xw=",
            },
            patch_strip = 1,
        ),
    },
    "ninja": {
        "1.10.2": _module(
            registry_version = "1.10.2",
            urls = ["https://github.com/ninja-build/ninja/archive/refs/tags/v1.10.2.tar.gz"],
            integrity = "sha256-zjWGVBHwSQNoqPw4PykHHeZpDLrcJ3BHNJeCIfJeK+0=",
            strip_prefix = "ninja-1.10.2",
            overlay = {
                "BUILD.bazel": "sha256-wTJ0uixG0JIirVcI+iset1WWi/a4uJDCxl3FoPQyggk=",
                "MODULE.bazel": "sha256-E0aHf5VPW1leEAvRLvL9dxEhKFpLkTN4EO8jPtvM2ZM=",
            },
        ),
        "1.11.1": _module(
            registry_version = "1.11.1",
            urls = ["https://github.com/ninja-build/ninja/archive/refs/tags/v1.11.1.tar.gz"],
            integrity = "sha256-MXR65jMhPx7aOEJob4PCqhQS4PVpHRwU27zGf+dADOo=",
            strip_prefix = "ninja-1.11.1",
            overlay = {
                "BUILD.bazel": "sha256-N+YVatGIR9eKGSbMF94Zk3NNkz0QGHr5xmc1ma2AtGo=",
                "MODULE.bazel": "sha256-Tt5+aCUy8HiytA1aBGPofmZZF86YnYXAYqEpYO/KSc4=",
            },
        ),
        # The only entry still carrying its BUILD file as patches rather than
        # an overlay: 1.12.1.bcr.2 predates the switch, and a published
        # registry version is immutable.
        "1.12.1": _module(
            registry_version = "1.12.1.bcr.2",
            urls = ["https://github.com/ninja-build/ninja/archive/refs/tags/v1.12.1.tar.gz"],
            integrity = "sha256-ghvf9Io/aDvEuztvC1/nstZHz2XVKutjMoyRpsbfKFo=",
            strip_prefix = "ninja-1.12.1",
            patches = {
                "add_build_file.patch": "sha256-F5nMhzzixO5U0Olw4BrRYuchNPyA7k1NMSgdmaM86zk=",
                "module_dot_bazel.patch": "sha256-GtZQTdRWQNP4OrW2Zyb1GjmxC5z+T2tRDH3c19whHSU=",
            },
        ),
        "1.13.0": _module(
            registry_version = "1.13.0",
            urls = ["https://github.com/ninja-build/ninja/archive/refs/tags/v1.13.0.tar.gz"],
            integrity = "sha256-8IZB0ACZqeQNROwBRvhBxHKuWLfm3VF77jlFz9kjzt8=",
            strip_prefix = "ninja-1.13.0",
            overlay = {
                "BUILD.bazel": "sha256-3AEfarVIkfqP/Z6B680UWAeSCOAcVbaId3Tl+1AMZJI=",
                "MODULE.bazel": "sha256-269iOzhR5TlS4dibC6rqnfrE5Elp92L2GdwMGQBeYCI=",
            },
        ),
        "1.13.1": _module(
            registry_version = "1.13.1",
            urls = ["https://github.com/ninja-build/ninja/archive/refs/tags/v1.13.1.tar.gz"],
            integrity = "sha256-8AVa0Dab8uNylVulUSjQAM/MIXdwV4BgFbReSsy+vyM=",
            strip_prefix = "ninja-1.13.1",
            overlay = {
                "BUILD.bazel": "sha256-3AEfarVIkfqP/Z6B680UWAeSCOAcVbaId3Tl+1AMZJI=",
                "MODULE.bazel": "sha256-c0jFtjXTNqsJyIplterTjp4u1Sz18KB0dAPp1GWLV2Y=",
            },
        ),
        "1.13.2": _module(
            registry_version = "1.13.2",
            urls = ["https://github.com/ninja-build/ninja/archive/refs/tags/v1.13.2.tar.gz"],
            integrity = "sha256-l01rL07u+iViXTTaPLNr3Ovn+85A9MFqwINf0cDLrhc=",
            strip_prefix = "ninja-1.13.2",
            overlay = {
                "BUILD.bazel": "sha256-3AEfarVIkfqP/Z6B680UWAeSCOAcVbaId3Tl+1AMZJI=",
                "MODULE.bazel": "sha256-XyjGGM/2OBHg0cTSZK/E64a5pmC/G6yjjqOFwNv+PSY=",
            },
        ),
    },
    "pkgconf": {
        "3.0.7": _module(
            registry_version = "3.0.7",
            urls = ["https://github.com/pkgconf/pkgconf/releases/download/pkgconf-3.0.7/pkgconf-3.0.7.tar.gz"],
            integrity = "sha256-AoiJeW/W1VbgGdNbjo1o0yHLtc+YJ9PqdlNiVilkE0U=",
            strip_prefix = "pkgconf-3.0.7",
            overlay = {
                "BUILD.bazel": "sha256-rUU6hy53SMwtnPyzxMmm2GN3qgwdX4CCPUAEg4NA9ew=",
                "MODULE.bazel": "sha256-tA9r/Re+vmXnYG6XhBfsRe0WZyzXssXEP3pV/JGqTww=",
                "bazel_test_main.cc": "sha256-jwkIjBtImMACKhzjjCsfZh9YuPYhv4LRdEnrpJBytmc=",
                "utils.bzl": "sha256-605eh/F74fkMGRzANEyzk7Y7vYawaDxumn8nCn9YypE=",
            },
        ),
    },
}

# Modules rfcc never loads from, but which the tool BUILD files above need:
# make's and pkgconf's run their configure checks through rules_cc_autoconf,
# which in turn needs nlohmann_json. Every version in `BCR_TOOLS` resolves to
# the same two, so there is one entry each rather than a per-version table.
BCR_CLOSURE = {
    "nlohmann_json": _module(
        registry_version = "3.12.0.bcr.1",
        urls = ["https://github.com/nlohmann/json/releases/download/v3.12.0/include.zip"],
        integrity = "sha256-uMsO8t1/V/GJM5l8mTS7H6liWU9wHNWo08LIBUFVk3I=",
        # The release zip ships a cc_library with no load statement; the BCR
        # patches the load in and adds the singleheader target that
        # rules_cc_autoconf links against.
        patches = {
            "add_singleheader_target.patch": "sha256-31q3C7/IKxKXXEvCQj9JnNEh9XKp1lpUk6hWkbarKl4=",
            "module_dot_bazel.patch": "sha256-wgSjgZXTbdIrL+vynluqdR9sjViQ09rG1rxbwzL5YCA=",
        },
    ),
    "rules_cc_autoconf": _module(
        registry_version = "0.24.0",
        urls = ["https://github.com/periareon/rules_cc_autoconf/releases/download/0.24.0/rules_cc_autoconf-0.24.0.tar.gz"],
        integrity = "sha256-bbTRzLQWUVGBZALHP9wbiIac3+wb/vFVcIjPY2iwRqQ=",
    ),
}

def bcr_tool_module(module, version):
    """Return the BCR module that builds `version` of the tool it ships.

    Args:
        module: a key of `BCR_TOOLS`, i.e. the module's registry name (`make`,
            `ninja` or `pkgconf`).
        version: an exact tool version, i.e. a key of `BCR_TOOLS[module]`.

    Returns:
        The module struct built by `_module`.
    """
    modules = BCR_TOOLS[module]

    # Reachable: the version comes from a `rules_foreign_cc_dependencies`
    # argument, so it is whatever the user typed. `module` is not -- every
    # caller passes a literal -- so it needs no check of its own.
    if version not in modules:
        fail("Unsupported {} version: {}. Known versions: {}".format(
            module,
            version,
            sorted(modules),
        ))
    spec = modules[version]

    # `registry_version` restates the key except on a `.bcr.N` re-release, and
    # it is the only field that decides which registry directory is read. A bump
    # that edits the key but not the field would otherwise keep fetching the old
    # module's archive, overlay and patches under the new version's name.
    if spec.registry_version != version and not spec.registry_version.startswith(version + ".bcr."):
        fail(("BCR_TOOLS[{}][{}] has registry_version {}, which is neither {} " +
              "nor a {}.bcr.N re-release of it. One of the two is a typo.").format(
            module,
            version,
            spec.registry_version,
            version,
            version,
        ))
    return spec
