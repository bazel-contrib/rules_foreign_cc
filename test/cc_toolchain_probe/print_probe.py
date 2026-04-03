import sys
from pathlib import Path


def main() -> int:
    probe = Path(sys.argv[1])
    sys.stdout.write(probe.read_text())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
