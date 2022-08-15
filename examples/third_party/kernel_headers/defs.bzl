load("@rules_foreign_cc//foreign_cc:defs.bzl", "make")

def linux_kernel_headers(name, config, kernel_version, environment = None):
    env = {
        "INSTALL_HDR_PATH": "$$INSTALLDIR",
        "KCONFIG_CONFIG": "$(execpath " + config + ")",
    }
    if not environment == None:
        env.update(environment)

    make(
        name = name,
        out_headers_only = True,
        # olddefconfig chooses default values for all missing keys in config
        # It also changes your configuration if it doesn't make sense
        # For example if your config had x86_64 everywhere but you specified CONFIG_64BIT=n
        # It would change things like:
        # CONFIG_X86_32=y
        # The default is chosen from the environment variables for ARCH and maybe more
        # set them using environment variable here
        targets = ["olddefconfig", "headers_install"],
        # TODO: this assumes that the bzlmod repo name will not change its name
        lib_source = "@kernel_headers_" + kernel_version + "//:src",
        build_data = [config],
        env = env,
        out_include_dir = "include",
        visibility = ["//visibility:public"],
    )
