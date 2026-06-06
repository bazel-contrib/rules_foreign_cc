# test/integration/scenarios.bzl
"""Macro for declaring a bazel-in-bazel integration-test scenario.

Each scenario is a self-contained workspace directory under test/integration/.
The directory is `--deleted_packages`-ed at the outer level (see
.bazelrc.deleted_packages) so the outer Bazel does not load it as a
sub-package and `glob_workspace_files()` sees its files as plain inputs.

`workspace_files` always includes `//:distribution` so the rfcc source tree
is staged into the runfiles tree, letting each scenario's
`local_path_override(module_name = "rules_foreign_cc", path = "../../..")`
resolve.

Two scenario shapes share this one harness:
  * dual_mode = True   - the scenario ships both a MODULE.bazel and a
                         WORKSPACE.bazel; the inner build runs in whichever
                         pure mode the outer Bazel uses (detected via
                         bzlmod_enabled.bzl). Used by the `basic` smoke test
                         so the workspaces and bzlmod CI lanes each exercise
                         their own path.
  * dual_mode = False  - bzlmod-only scenario (ships MODULE.bazel + an empty
                         WORKSPACE). Used by the hub-and-spoke API scenarios,
                         which only have meaning under bzlmod.
"""

load("@bazel_binaries//:defs.bzl", "bazel_binaries")
load(
    "@rules_bazel_integration_test//bazel_integration_test:defs.bzl",
    "bazel_integration_test",
    "integration_test_utils",
)
load(":bzlmod_enabled.bzl", "BZLMOD_ENABLED")

# These are bazel-in-bazel tests: runner.sh spawns a nested Bazel that builds
# the scenario. That inner Bazel breaks the outer test's normal isolation in
# three specific ways:
#   exclusive      - the inner Bazel starts its own server and is heavy on
#                    CPU/RAM; only a couple can run at once before reliability
#                    and runtime suffer. Bazel has no knob to cap concurrency,
#                    so we serialize entirely.
#   no-sandbox     - runner.sh runs the inner `bazel build` with no
#                    --output_user_root, so it defaults its output base to
#                    $HOME/.cache/bazel. The sandbox confines writes to the
#                    action's outputs, so those home-dir writes would fail.
#   no-remote-exec - a nested Bazel server needs a persistent local workspace;
#                    the CI RBE setup can't run it remotely.
# rules_python's integration tests use the same three tags for the same
# reasons (tests/integration/integration_test.bzl).
_COMMON_TAGS = [
    "exclusive",
    "no-sandbox",
    "no-remote-exec",
]

def scenario(
        name,
        env = None,
        dual_mode = False,
        enforce_lock = False,
        timeout = "long",
        **kwargs):
    """Declare a bazel-in-bazel integration-test scenario.

    Args:
      name: scenario directory name under test/integration/.
      env: dict of assertion env vars passed to runner.sh. Recognized keys:
           EXPECT_BUILD (target that must build), EXPECT_BUILD_FAIL (target
           whose build must fail), EXPECT_CQUERY (cquery expression to run),
           EXPECT_STDOUT_PATTERN (regex EXPECT_CQUERY's output must match).
      dual_mode: if True, the inner build runs in the outer Bazel's mode
           (WORKSPACE or bzlmod); if False it always runs under pure bzlmod.
      enforce_lock: if True, the bzlmod inner build passes
           --lockfile_mode=error so a committed MODULE.bazel.lock is enforced.
      timeout: test timeout; defaults to "long" because a cold inner build
           downloads Bazel and bootstraps make/pkg-config from source.
      **kwargs: forwarded to bazel_integration_test.
    """
    env = dict(env or {})
    env.setdefault("SCENARIO", name)
    if dual_mode:
        env["DUAL_MODE"] = "1"

        # True in the bzlmod and mixed lanes, false in the workspaces lane.
        env["OUTER_BZLMOD"] = "1" if BZLMOD_ENABLED else "0"
    if enforce_lock:
        env["ENFORCE_LOCK"] = "1"
    bazel_integration_test(
        name = name + "_test",
        timeout = timeout,
        bazel_binaries = bazel_binaries,
        bazel_version = bazel_binaries.versions.current,
        test_runner = "//test/integration:runner.sh",
        workspace_path = name,
        workspace_files = integration_test_utils.glob_workspace_files(name) + [
            "//:distribution",
        ],
        env = env,
        tags = (kwargs.pop("tags", None) or []) + _COMMON_TAGS,
        **kwargs
    )
