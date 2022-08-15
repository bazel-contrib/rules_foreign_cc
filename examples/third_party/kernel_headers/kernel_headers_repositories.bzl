load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def download_kernel_sources(version, sha256, url = ""):
    if len(url) == 0:
        major = version[0]
        url = "https://cdn.kernel.org/pub/linux/kernel/v" + major + ".x/linux-" + version + ".tar.gz"
    http_archive(
        name = "kernel_headers_" + version,
        build_file = Label("//kernel_headers:BUILD.kernel"),
        patches = [
            Label("//kernel_headers:kernel_install_hdr_patch"),
        ],
        sha256 = sha256,
        strip_prefix = "linux-" + version + "/",
        urls = [url],
    )

# buildifier: disable=unnamed-macro
def kernel_headers_repositories(
        kernel_version = "4.14.151",
        kernel_sha256 = "9b481473b29e63b332ef3d62c08462489ccfcd12638b1279c5aba81065002132"):
    """
    Call this function from the WORKSPACE file to initialize linux_kernel_headers dependencies

    Args:
        kernel_version: The kernel version
    """
    download_kernel_sources(version = kernel_version, sha256 = kernel_sha256)
