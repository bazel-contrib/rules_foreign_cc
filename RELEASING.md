# Releasing rules_foreign_cc

Releases are cut by pushing a tag. Everything after that is automated: building
the release archive, creating the GitHub release, and opening the Bazel Central
Registry (BCR) entry.

## One-time setup

The BCR publish step needs a `BCR_PUBLISH_TOKEN` secret. Without it the release
is still created, but the `publish` job fails and no BCR entry is opened.

It must be a **classic** personal access token with the `repo` and `workflow`
scopes, belonging to an account with push access to
[bazel-contrib/bazel-central-registry](https://github.com/bazel-contrib/bazel-central-registry)
(the registry fork the entry branch is pushed to). Save it under
_Settings > Secrets and variables > Actions_ on this repository or on the
bazel-contrib org.

Fine-grained tokens do not work as-is, because they cannot open pull requests
against public repositories. To use one, set `open_pull_request: false` in
`.github/workflows/publish.yaml`; the workflow then prints a URL to open the PR
by hand.

## Version numbering

`rules_foreign_cc` is pre-1.0 and follows the usual pre-1.0 convention: breaking
changes go in a minor bump (`0.15.1` -> `0.16.0`), and a patch bump is reserved
for fixes that break nothing (`0.16.0` -> `0.16.1`).

Tags are **bare** version numbers with no `v` prefix: `0.16.0`, not `v0.16.0`.
This matters in two places that are already configured for it, so do not change
the scheme casually:

- `tag_prefix: ""` in `.github/workflows/publish.yaml`.
- `strip_prefix` in `.bcr/source.template.json`, which resolves to
  `rules_foreign_cc-<version>` and must match the prefix `release_prep.sh` puts
  in the archive.

A `-` in the tag means prerelease (see [Prereleases](#prereleases)), so it is the
one character that changes how the release is treated. Do not put a `-` in a tag
you intend as a real release.

## Do not hand-edit these

- **`version.bzl`** is stamped by `git archive` at release time, via the
  `export-subst` attribute in `.gitattributes`. A git checkout reports `0.0.0`;
  the release archive carries the real version. Leave the `$Format:...$`
  placeholder alone.
- **`module(version = ...)` in `MODULE.bazel`** stays `0.0.0`. Publish to BCR
  patches the real version into the registry's copy via a generated
  `module_dot_bazel_version.patch`. This is deliberate and matches rules_python.

## Checklist

1. **Pick the version.** Read the `Unreleased` section of [NEWS.md](NEWS.md) and
   decide minor vs patch per the policy above.

2. **Roll the changelog.** In `NEWS.md`, rename `## Unreleased` to
   `## <version> (<YYYY-MM-DD>)` and open a fresh empty `## Unreleased` section
   above it. Land this as a normal PR and let CI pass before tagging.

3. **Check CI is green on the commit you are about to tag.** Buildkite is the
   real signal here; it covers 6 platforms across Bazel 7/8 and all three bzlmod
   modes. The release workflow only re-runs `bazel test //...` on one Linux
   runner.

4. **Tag and push.** Use an annotated tag; its message becomes part of the
   release notes.

   ```shell
   git checkout main
   git pull
   git tag -a 0.16.0
   git push origin 0.16.0
   ```

5. **Watch the Release workflow.** See "What the automation does" below.

6. **Mark the BCR pull request ready for review.** The entry PR against
   [bazelbuild/bazel-central-registry](https://github.com/bazelbuild/bazel-central-registry)
   is opened as a draft. Marking it ready for review is what approves it, since
   GitHub does not let an author review their own PR. A link to the PR is in the
   `publish` job summary.

7. **Confirm the entry landed** at
   `https://registry.bazel.build/modules/rules_foreign_cc`, then announce it if
   you want to.

## What the automation does

Pushing a tag matching `*.*.*` triggers `.github/workflows/release.yml`, which
runs three jobs in order.

| Job | What it does |
| --- | --- |
| `release` | Calls the shared `bazel-contrib/.github` release workflow. Runs `bazel test //...`, then `.github/workflows/release_prep.sh <tag>` to build `rules_foreign_cc-<tag>.tar.gz` and emit the release notes on stdout. Attests build provenance and creates the GitHub release **as a draft**. |
| `publish` | Calls `.github/workflows/publish.yaml`, which runs Publish to BCR: it generates the entry from `.bcr/`, uploads attestations to the draft release, pushes a branch to the registry fork, and opens the entry PR. **Skipped for prerelease tags** -- see below. |
| `finalize` | Un-drafts the GitHub release. Runs whether `publish` succeeded or was skipped, so a prerelease does not stay a draft. |

The draft-until-BCR-succeeds ordering is deliberate. Attestations have to be
attached while the release is still a draft, which is also what GitHub immutable
releases require, and it means a failed BCR publish leaves nothing public.

## Prereleases

A tag containing `-` is a prerelease. Everything is derived from the tag, so
there is nothing to configure:

```shell
git tag -a 0.17.0-rc1
git push origin 0.17.0-rc1
```

That gets you a GitHub release marked "Pre-release" with the archive attached and
build provenance attested, and **no BCR entry**. The `publish` job is skipped for
these tags on purpose: a registry entry cannot be changed once merged, so a
throwaway release candidate would sit in the module's version list permanently.

Tell testers to point at the tag directly rather than a registry version:

```starlark
bazel_dep(name = "rules_foreign_cc", version = "0.17.0-rc1")
archive_override(
    module_name = "rules_foreign_cc",
    strip_prefix = "rules_foreign_cc-0.17.0-rc1",
    urls = ["https://github.com/bazel-contrib/rules_foreign_cc/releases/download/0.17.0-rc1/rules_foreign_cc-0.17.0-rc1.tar.gz"],
)
```

Prerelease versions sort below the corresponding final release in Bazel's
version resolution (`0.17.0-rc1` < `0.17.0`), so a release candidate can never be
selected in preference to a real release.

Two consequences worth knowing:

- Because `publish` is skipped, a prerelease does **not** exercise the BCR
  publish path. The first real release after any change to `.bcr/` or
  `publish.yaml` is the first time that code runs.
- Prereleases are the one case where you can safely delete and re-push a tag, as
  long as you do it promptly.

There is no automatic `-rcN` numbering. Pick the next number yourself.

## When something fails

**The `release` job failed.** Nothing was published. Delete the tag, fix the
problem, and tag again:

```shell
git push --delete origin 0.16.0
git tag -d 0.16.0
```

**The `publish` job failed.** The draft release exists but there is no BCR
entry. Fix the cause, then re-run just the publish step, passing the run id of
the Release workflow run that built the archive:

```shell
gh workflow run publish.yaml \
  -f tag_name=0.16.0 \
  -f release_artifacts_run_id=<release-workflow-run-id>
```

The run id is needed because integrity hashes are computed from that run's
uploaded artifacts. If the release has already been published (not a draft), you
can omit it and the archive is fetched from the release itself.

**The `.bcr/` templates were wrong.** Rather than re-tagging, set
`templates_ref` in `.github/workflows/publish.yaml` to a ref containing the
corrected templates and re-run the publish workflow.

**The release is stuck as a draft.** The `finalize` job did not run. Publish it
by hand:

```shell
gh release edit 0.16.0 --draft=false --repo bazel-contrib/rules_foreign_cc
```

## Points of no return

- **A merged BCR entry cannot be changed.** Registry entries are immutable once
  committed. A bad version has to be yanked and replaced with a new one, so it is
  worth reading the entry PR before marking it ready for review.
- **A published tag should be treated as permanent.** Deleting a tag that people
  may already have fetched breaks their builds. Deleting an unpublished tag
  immediately after a failed release is fine; deleting one hours later is not.

## Files involved

| Path | Purpose |
| --- | --- |
| `.github/workflows/release.yml` | Tag trigger and job ordering. |
| `.github/workflows/release_prep.sh` | Builds the archive; its stdout is the release notes. |
| `.github/workflows/publish.yaml` | BCR publication, with a manual-retry trigger. |
| `.bcr/source.template.json` | Archive URL and `strip_prefix` for the entry. |
| `.bcr/metadata.template.json` | Maintainers. BCR emails these people when a release fails, and they are the accounts allowed to approve an entry PR. |
| `.bcr/presubmit.yml` | The CI matrix BCR runs against the candidate entry, using `test/integration/basic` as the test module. |
| `version.bzl` | Stamped at release time; see above. |
| `NEWS.md` | Changelog, rolled by hand at step 2. |
