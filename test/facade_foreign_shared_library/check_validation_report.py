import sys
from pathlib import Path


def main() -> int:
    report = Path(sys.argv[1]).read_text().strip()
    expected = " ".join(sys.argv[2:])
    if report != expected:
        raise SystemExit(
            "unexpected validation report: {!r} != {!r}".format(report, expected)
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
