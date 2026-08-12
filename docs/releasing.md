# Releasing

Three `ARG` lines at the top of `Dockerfile` pin the upstream releases:

    ARG SIDPLAYFP_VERSION=v3.2.0
    ARG LIBSIDPLAYFP_VERSION=v3.1.0
    ARG LIBRESIDFP_VERSION=v1.2.1

`SIDPLAYFP_VERSION` is the source of truth for the image version.

## Why three pins

The projects are separate repositories on independent version series. They shared numbering
through v3.0.1, then diverged: sidplayfp released v3.0.2 on 2026-05-28 with no matching
library release, and is now a minor version ahead. sidplayfp's `configure` only requires
`libsidplayfp >= 2.0`, so matching tag names was never a guarantee, and building both from a
single ref breaks whenever the numbers differ.

libresidfp is a hard requirement, not an extra: since libsidplayfp 3.x the SID engine lives
in its own project, and libsidplayfp's `configure` merely warns when it is absent. The
resulting library builds and installs, then fails at play time with `Requested SID emulation
not built in`. The build asserts `libsidplayfp.so` links `residfp`, and `tests/smoke.sh`
renders a tune and asserts the output is not silent.

## Workflows

| Workflow | Trigger | Action |
| --- | --- | --- |
| `ci` | pull request, push to main | hadolint, shellcheck, actionlint, build, `tests/smoke.sh` |
| `release` | push to main touching `Dockerfile`, manual | build, smoke test, push images, create GitHub release |
| `upstream-bump` | daily 05:23 UTC, manual | pin the latest release of all three projects and open a PR |

`upstream-bump` builds and smoke tests the new pins before opening the PR, because pull
requests opened with `GITHUB_TOKEN` do not start workflow runs; the PR body links the run
that tested it. Opening PRs requires *Allow GitHub Actions to create and approve pull
requests* under Settings → Actions → General.

Merging a bump PR publishes `vX.Y.Z`, `X.Y.Z` and `latest`, and creates the matching GitHub
release. Re-running `release` for an existing version refreshes the images and leaves the
release alone.

## Secrets

| Name | Kind | Required | Purpose |
| --- | --- | --- | --- |
| `GITHUB_TOKEN` | built in | yes | release creation, bump PR |
| `DOCKER_USERNAME` | secret | yes | Docker Hub push |
| `DOCKER_TOKEN` | secret | yes | Docker Hub access token |
| `DOCKERHUB_IMAGE` | variable | no | image repository, default `anarkiwi/sidplayfp` |
