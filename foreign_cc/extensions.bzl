"""Entry point for extensions used by bzlmod."""

load("@bazel_features//:features.bzl", "bazel_features")
load("//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")
load("//foreign_cc/private:default_versions.bzl", _DEFAULT_VERSIONS = "DEFAULT_VERSIONS")
load("//toolchains:prebuilt_toolchains.bzl", "prebuilt_toolchains")

cmake_toolchain_version = tag_class(attrs = {
    "version": attr.string(doc = "The cmake version", default = _DEFAULT_VERSIONS["cmake"]),
})

make_toolchain_version = tag_class(attrs = {
    "version": attr.string(doc = "The make version", default = _DEFAULT_VERSIONS["make"]),
})

meson_toolchain_version = tag_class(attrs = {
    "version": attr.string(doc = "The meson version", default = _DEFAULT_VERSIONS["meson"]),
})

ninja_toolchain_version = tag_class(attrs = {
    "version": attr.string(doc = "The ninja version", default = _DEFAULT_VERSIONS["ninja"]),
})

pkgconfig_toolchain_version = tag_class(attrs = {
    "version": attr.string(doc = "The pkgconfig version", default = _DEFAULT_VERSIONS["pkgconfig"]),
})

def _init(module_ctx):
    versions = dict(_DEFAULT_VERSIONS)

    pinned_kw = {}

    for mod in module_ctx.modules:
        if not mod.is_root:
            for toolchain_type in versions.keys():
                for toolchain in getattr(mod.tags, toolchain_type):
                    versions[toolchain_type] = toolchain.version
                    pinned_kw[toolchain_type + "_version"] = toolchain.version

    rules_foreign_cc_dependencies(
        register_toolchains = False,
        register_built_tools = True,
        register_default_tools = False,
        register_preinstalled_tools = False,
        register_built_pkgconfig_toolchain = True,
        # These should be registered via bzlmod entries instead
        register_repos = False,
        **pinned_kw
    )

    prebuilt_toolchains(
        cmake_version = versions["cmake"],
        ninja_version = versions["ninja"],
        register_toolchains = False,
    )

    if bazel_features.external_deps.extension_metadata_has_reproducible:
        return module_ctx.extension_metadata(reproducible = True)
    else:
        return None

tools = module_extension(
    implementation = _init,
    tag_classes = {
        "cmake": cmake_toolchain_version,
        "make": make_toolchain_version,
        "meson": meson_toolchain_version,
        "ninja": ninja_toolchain_version,
        "pkgconfig": pkgconfig_toolchain_version,
    },
)
