import os
import runpy
import sys

from python.runfiles import runfiles


# Meson frequently spawns Python subprocesses, either internally or via
# project code such as `python.find_installation()` checks. When Meson is
# launched from a Bazel `py_binary`, those child interpreters do not
# automatically inherit the wheel-provided `site-packages` entries that were
# attached to the wrapper target.
#
# This wrapper preserves those `site-packages` paths in `PYTHONPATH` before
# handing off to the real `meson.py` entrypoint, which is passed in as a
# runfiles rlocation via `REAL_MESON`.
def _site_packages_from_sys_path():
    paths = []
    seen = set()
    for entry in sys.path:
        if not entry or "site-packages" not in entry:
            continue
        if entry in seen:
            continue
        seen.add(entry)
        paths.append(entry)
    return paths


def _find_meson_main():
    rlocation = os.environ.get("REAL_MESON")
    if not rlocation:
        raise RuntimeError("REAL_MESON is not set")

    path = runfiles.Create().Rlocation(rlocation)
    if path and os.path.isfile(path):
        return path

    raise RuntimeError(
        "Failed to locate meson main from REAL_MESON={!r}".format(rlocation)
    )


def main():
    extra_paths = _site_packages_from_sys_path()
    if extra_paths:
        existing = os.environ.get("PYTHONPATH")
        os.environ["PYTHONPATH"] = os.pathsep.join(
            extra_paths + ([existing] if existing else [])
        )

    meson_main = _find_meson_main()
    sys.argv[0] = meson_main
    runpy.run_path(meson_main, run_name="__main__")


if __name__ == "__main__":
    main()
