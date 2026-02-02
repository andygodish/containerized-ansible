# Versioning & releases (upver)

This repo uses a small tool called **upver** to map an **upstream version** (Ansible Core) into this project’s **release version/tag scheme**.

- upver: https://github.com/andygodish/upver

## Goals

- Track the upstream dependency version directly (so it’s obvious what Ansible version is inside the image)
- Still allow downstream iterations (docs, scripts, build tweaks) without “lying” about upstream
- Keep the release process mostly automated and repeatable

## Version format

Releases are tagged as:

- `v<ansible-core>-<seq>`

Example:

- `v2.20.2-1`
  - `2.20.2` matches the upstream **ansible-core** version
  - `-1` is the downstream **sequence** bump

### When does the sequence bump?

- If upstream **does not change**: increment the sequence
  - `2.20.2-0 → 2.20.2-1 → 2.20.2-2 ...`

### What happens when upstream changes?

- If upstream **does change**: set the base to the new upstream version and reset sequence to `-0`
  - `2.20.2-2 → 2.20.3-0`

## What upver reads/writes in this repo

`upver.yaml` defines where to read the project version and the upstream version from:

- **Project version**: `.release-please-manifest.json` (root key `"."`)
- **Upstream version**: `ansible-version.json` (key `"ansible-core"`)
- **Changelog**: `CHANGELOG.md`

Renovate is configured to update the upstream version in `ansible-version.json` (and also the default in `aliases.sh`).

## Release automation (GitHub Actions)

There are two workflows that matter:

### 1) Build / test workflow (`.github/workflows/build.yaml`)

This runs on PRs and on certain pushes to `main`.

- Reads `ansible-version.json`
- Builds the image with `make build ANSIBLE_VERSION=<ansible-core>`
- Runs `make test ...`

This validates that the repo state can build and the image behaves.

### 2) Release workflow (`.github/workflows/release.yaml`)

This workflow runs on every push to `main` and has a “two-stage” behavior.

#### Stage A: create/update the release PR (version bump)

On a normal merge to `main` (i.e. not a release PR merge), the workflow:

1. Runs `upver --apply --changelog`
2. Opens/updates a PR on branch `release/upver` containing changes to:
   - `.release-please-manifest.json`
   - `CHANGELOG.md`

This PR is the “release candidate”.

#### Stage B: tag and publish (when release PR is merged)

When you merge the `release/upver` PR, the workflow detects it by noticing that `.release-please-manifest.json` changed in that push.

Then it:

1. Creates/pushes a git tag: `v<version>`
2. Builds and pushes a multi-arch image to GHCR:
   - `ghcr.io/<owner>/containerized-ansible:<version>`
   - `ghcr.io/<owner>/containerized-ansible:latest`

## Changelog notes (merge strategy matters)

upver builds the changelog from:

- first-parent history
- non-merge commits

So if you merge PRs using **“Create a merge commit”**, the merge commit itself is ignored for changelog purposes and the PR may not appear as a bullet.

If you want PR changes to appear as explicit changelog entries, prefer **“Squash and merge”** (or rebase/fast-forward), so the resulting commit on `main` is a non-merge commit.
