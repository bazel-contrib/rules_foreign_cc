import os
import runpy
import sys


# Meson can spawn child Python interpreters while probing the build
# environment. Those children need both wheel `site-packages` and the import
# root that contains `mesonbuild` itself, because Meson may re-exec via
# `python -m mesonbuild.mesonmain`.
def _inherited_pythonpath_entries():
    paths = []
    seen = set()
    for entry in sys.path:
        if not entry:
            continue
        keep = "site-packages" in entry or os.path.isdir(
            os.path.join(entry, "mesonbuild"),
        )
        if not keep:
            continue
        if entry in seen:
            continue
        seen.add(entry)
        paths.append(entry)
    return paths


def main():
    extra_paths = _inherited_pythonpath_entries()
    if extra_paths:
        existing = os.environ.get("PYTHONPATH")
        os.environ["PYTHONPATH"] = os.pathsep.join(
            extra_paths + ([existing] if existing else [])
        )

    runpy.run_module("mesonbuild.mesonmain", run_name="__main__", alter_sys=True)


if __name__ == "__main__":
    main()
