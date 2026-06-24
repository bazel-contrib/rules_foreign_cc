"""Doc/version sync lint.

Asserts that every concrete tool version the bzlmod docs pin is a version
`rules_foreign_cc` actually ships. The accepted set is the union of every
version-like key (exact `a.b.c` patches and `a.b.x` wildcards) declared in the
generated `toolchains/private/*_versions.bzl` data files -- the same data the
extension validates tags against.

Two doc surfaces carry version literals that go stale on a generator bump, and
both are scanned:

  * `tools.<tool>(version = "X")` extension-tag examples.
  * Spoke-repo references -- binary (`@cmake-X-plat`, `@ninja_X_plat`) and
    source (`@<tool>_src_X`) -- which encode a version in the repo name.

A removed/renamed version in either surface would otherwise only surface as a
confusing "no such repository" / unsupported-version error in a downstream
build. Run as a py_test; the docs and version files are passed via `data`.
"""

import re
import sys

# `version = "X"` argument. Restricted to lines also containing `tools.` (a
# tag call) so bazel_dep(version=...) / module(version=...) noise is ignored.
# Doc tag examples keep the tool and the version on the same logical line in
# practice, but to be safe we scan version args anywhere a `tools.<tool>`
# token appears within the same paragraph (see _tag_versions).
_TOOLS_TOKEN = re.compile(r"tools\.[a-z0-9_]+\(")
_VERSION_ARG = re.compile(r'version\s*=\s*"([^"]+)"')

# Spoke-repo references that encode a version in the repo name:
#   @cmake-3.31.12-linux-x86_64   (binary spoke: @<tool>-<v>-<os>-<arch>)
#   @ninja-1.13.2-linux-x86_64    (binary spoke, same scheme)
#   @ninja_1.13.2_toolchains      (per-version binary aggregator: @<tool>_<v>_toolchains)
#   @cmake_src_3.31.12            (source: @<tool>_src_<v>)
#   @make_src_4.4                 (source: two-component make release)
# Binary spokes use `<tool>-` (see binary_spokes.bzl's BINARY_SPOKE_REPO_FORMAT);
# the aggregator repos still use `<tool>_`, so accept either separator after the
# tool name.
_SPOKE_REPO = re.compile(
    r"@(?:cmake[-_]|ninja[-_]|[a-z0-9]+_src_)(\d+\.\d+(?:\.(?:\d+|x))?)",
)

# A version-like token: exact `a.b` / `a.b.c` patch or `a.b.x` wildcard. make
# ships two-component releases (`4.3`, `4.4`), so the trailing patch is optional.
_VERSION_TOKEN = re.compile(r'"(\d+\.\d+(?:\.(?:\d+|x))?)"')


def accepted_versions(version_files):
    accepted = set()
    for path in version_files:
        with open(path, encoding="utf-8") as f:
            text = f.read()
        for m in _VERSION_TOKEN.finditer(text):
            accepted.add(m.group(1))
    return accepted


def _tag_versions(text):
    """Yield versions from `tools.<tool>(... version = "X" ...)` paragraphs.

    A doc tag example may span multiple lines (mode/version on separate
    lines), so we split on blank lines and scan any paragraph that contains a
    `tools.<tool>(` token for `version = "..."` args. This avoids the brittle
    non-greedy `(...)\\)` capture, which truncated on a nested `)` (a
    `select(...)`, `Label(...)`, or tuple inside the call).
    """
    for para in re.split(r"\n\s*\n", text):
        if not _TOOLS_TOKEN.search(para):
            continue
        for v in _VERSION_ARG.finditer(para):
            yield v.group(1)


def doc_tool_versions(doc_files):
    """Return [(doc_path, version), ...] for every pinned doc version.

    Covers both `tools.<tool>(version=...)` tag examples and version-suffixed
    spoke-repo references.
    """
    found = []
    for path in doc_files:
        with open(path, encoding="utf-8") as f:
            text = f.read()
        versions = list(_tag_versions(text))
        versions += [m.group(1) for m in _SPOKE_REPO.finditer(text)]
        for version in versions:
            # `...` is an instructional fill-in-the-blank placeholder, not a
            # real version; skip it. (Only reachable from tag args.)
            if version == "...":
                continue
            found.append((path, version))
    return found


def main(argv):
    sep = argv.index("--")
    doc_files = argv[1:sep]
    version_files = argv[sep + 1 :]

    accepted = accepted_versions(version_files)
    if not accepted:
        print("version_sync_lint: no accepted versions parsed -- bad data inputs?")
        return 1

    failures = []
    checked = 0
    for path, version in doc_tool_versions(doc_files):
        checked += 1
        if version not in accepted:
            failures.append((path, version))

    if failures:
        print("version_sync_lint: doc tool versions not in the accepted set:")
        for path, version in failures:
            print('  {}: version = "{}"'.format(path, version))
        print("\nAccepted versions: {}".format(", ".join(sorted(accepted))))
        return 1

    # A lint that scanned nothing is broken, not passing: if a doc-format change
    # stops the version/spoke regexes from matching, `checked` stays 0 and a
    # stale version would slip through silently. Fail rather than pass vacuously.
    if checked == 0:
        print(
            "version_sync_lint: matched no tool versions in the doc files -- "
            "the regexes are probably stale against the doc format."
        )
        return 1

    print("version_sync_lint: {} doc tool version(s) all accepted.".format(checked))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
