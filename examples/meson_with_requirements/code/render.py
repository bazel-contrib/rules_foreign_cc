import os
import sys

from mako.template import Template


def main() -> int:
    template_path, output_path, expected_version = sys.argv[1:]

    actual_python = os.path.realpath(sys.executable).replace("\\", "/")
    executable_path = sys.executable.replace("\\", "/")
    if (
        ".runfiles/" not in executable_path
        and "/external/python_" not in actual_python
        and "/rules_python" not in actual_python
    ):
        raise RuntimeError(
            f"expected Bazel toolchain python, got {sys.executable!r}",
        )

    actual_version = f"{sys.version_info.major}.{sys.version_info.minor}"
    if actual_version != expected_version:
        raise RuntimeError(
            f"expected python version {expected_version!r}, got {actual_version!r}",
        )

    with open(template_path, encoding="utf-8") as template_file:
        template_text = template_file.read()

    rendered = Template(text=template_text).render(
        python_version=actual_version,
    )
    if output_path == "-":
        sys.stdout.write(rendered)
        return 0

    with open(output_path, "w", encoding="utf-8") as out:
        out.write(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
