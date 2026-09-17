"""A module representing the version of rules_foreign_cc"""

# Replaced by `git archive` via the `export-subst` attribute on this file in
# /.gitattributes, so the released tarball and GitHub's generated source
# archives both carry a real version. An unstamped git checkout keeps the
# literal placeholder, which is how VERSION falls back to "0.0.0".
#
# `match=*.*.*` limits `git describe` to release tags. At a release tag this
# expands to the bare version ("0.16.0"); at any other commit it expands to a
# describe string ("0.16.0-12-gabc1234").
# https://git-scm.com/docs/git-archive#Documentation/git-archive.txt-export-subst
_VERSION_PRIVATE = "$Format:%(describe:tags=true,match=*.*.*)$"

VERSION = "0.0.0" if _VERSION_PRIVATE.startswith("$Format") else _VERSION_PRIVATE
