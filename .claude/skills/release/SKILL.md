---
name: release
description: Cut a versioned release — detect the repo's release tooling and defer to it, otherwise compute the next SemVer from Conventional Commits, update CHANGELOG.md (Keep a Changelog), tag, and publish through the existing pipeline. Run only when the user invokes /release.
argument-hint: "[patch|minor|major|<x.y.z>|rc|beta] [--dry-run]"
disable-model-invocation: true
---

# Release

Arguments: `$ARGUMENTS`. With `--dry-run` (or no version given), compute and show everything but change nothing. Show the old → new version and the draft notes, and get confirmation before any commit, tag, push, or publish.

## 1. Detect existing release tooling and defer to it (check in order)
| Found | What "release" means here |
| --- | --- |
| `release-please-config.json` / `.release-please-manifest.json` / a `release-please-action` workflow | Don't hand-roll. The release is merging the open `autorelease: pending` PR. Force a version only with an empty commit carrying `Release-As: x.y.z`. |
| `.changeset/config.json` | Changesets: `npx changeset status`; release = merge the "Version Packages" PR (or `changeset version` → `changeset publish` → `changeset git-tag` on v3). |
| `pnpm-workspace.yaml` with `versioning:` | pnpm-native: `pnpm change status`, `pnpm version -r --dry-run`. |
| `.releaserc*`, `release.config.*`, `"release"` in package.json | semantic-release is CI-only: run `npx semantic-release --dry-run --no-ci` to preview; never release from a laptop. |
| `[tool.semantic_release]` / `[tool.commitizen]` / `.cz.toml` | `semantic-release version --print` / `cz bump --get-next` then `--dry-run`. |
| `cliff.toml` / `[tool.git-cliff]` | `git cliff --bumped-version` for the version, `git cliff --unreleased --tag vX.Y.Z --prepend CHANGELOG.md` for notes; bump manifests by hand. |
| none of the above | Manual path below. |

Then find the publish path: a workflow `on: push: tags` → pushing the tag publishes (watch it with `gh run watch`); `on: release: types: [published]` → the GitHub release must be created by a human credential or App token (`actions/create-github-app-token` v3: input `client-id`; `app-id` is deprecated), never `GITHUB_TOKEN`. Never publish to npm/PyPI from this machine when a trusted-publishing workflow exists; with no workflow, prefer npm staged publishing (`npm stage publish`, npm ≥ 11.15.0) so the user approves with 2FA (`npm stage approve <id>`) over a direct `npm publish`. If the repo uses release-please, its action should be v5 (node24); the README examples still show `@v4`.

## 2. Preflight (all must hold)
`git fetch origin --tags`; `git status --porcelain` empty; on the default branch; `git rev-list --left-right --count HEAD...origin/<branch>` is `0 0`; CI green on HEAD (`gh run list -b <branch> -L 3`); tests pass locally.

## 3. Compute the version (manual path)
- Base: `git describe --tags --abbrev=0 --match 'v[0-9]*'`, cross-checked with the manifest version (package.json / pyproject.toml / VERSION). Disagreement → stop and ask. No tags yet → release the manifest version as-is if it was never tagged; otherwise propose 0.1.0 and confirm.
- Commits: `git log <tag>..HEAD --no-merges --format='%H%x1f%B%x1e'`. Header `^(\w+)(\([^)]*\))?(!)?: .+`; breaking if `!` or a `BREAKING CHANGE:` / `BREAKING-CHANGE:` footer.
- Level = the highest of: breaking → major; `feat` → minor; `fix`/`perf`/`revert` → patch; anything else → no release (say "nothing to release" unless the user forces a version).
- 0.x policy (tools disagree, so be explicit): breaking or feat → 0.(y+1).0; fix → 0.y.(z+1); go to 1.0.0 only when the user asks.
- Pre-releases: Node uses SemVer `1.3.0-rc.0`; Python uses PEP 440 `1.3.0rc1` (`uv version --bump minor --bump rc`). Within the same base, bump only the counter. Stable notes are generated from the last *stable* tag.

## 4. Changelog (Keep a Changelog 2.0.0, https://keepachangelog.com/en/2.0.0/; link that version in the file header)
Rename `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD` (UTC date) and add a fresh empty Unreleased; fix the compare links at the bottom. Sections in order of urgency — Security, Removed, Changed, Deprecated, Fixed, Added — omitting empty ones; mark breaking changes with `**Breaking:**` inside their section. Summarize notable user-facing changes with the reason; don't paste the git log; drop anything not worth reading. No CHANGELOG.md yet → create one in this format.

## 5. Bump, commit, tag, push (after confirmation)
- Node: `npm version X.Y.Z --no-git-tag-version` (or `pnpm version …`); stage package.json + lockfile + CHANGELOG.md.
- Python (uv): `uv version X.Y.Z` (also relocks `uv.lock`); bump any hard-coded `__version__`; dynamic versions (hatch-vcs/setuptools-scm) → the tag is the version, skip the file bump.
- Other: bump `VERSION`/`version.txt` if present.
- `git commit -m "chore(release): vX.Y.Z"` → annotated tag `git tag -a vX.Y.Z -m "vX.Y.Z"` → `git push --atomic origin HEAD:<branch> vX.Y.Z` (push exactly that tag).
- No publish workflow: `gh release create vX.Y.Z --verify-tag --title vX.Y.Z -F notes.md` (+ `--prerelease`, or `--latest=false` for backports).

## 6. Verify
Watch the publish run to the end (`gh run watch <id> --exit-status`), then confirm the GitHub release page and the registry show the new version (`npm view <pkg> version`, PyPI page). Report the version, tag, links, and anything left manual.

## Gotchas
- Never `git push --tags` (pushes stray tags; more than 3 tags in one push fires no push events) and never `gh release create` without `--verify-tag` (it silently tags the default-branch tip; with immutable releases that tag name is burned forever).
- Releases are immutable in practice: npm never reuses a version, PyPI never reuses a filename, GitHub immutable releases lock tags. A bad release is fixed forward with a new patch (`npm deprecate` / PyPI yank the bad one) — never by deleting and re-tagging.
- `uv.lock` goes stale after any manual or tool bump of pyproject → run `uv lock` before committing.
- npm 11+: publishing a pre-release needs `--tag next`; publishing a version lower than the registry's highest (backport) needs `--tag` too.
- Tags/releases created with `GITHUB_TOKEN` don't trigger other workflows — publish in the same job or use a GitHub App token. Since 2026-06-11, PRs opened by a bot with `GITHUB_TOKEN` (release-please's release PR) run CI only after someone clicks "Approve workflows to run".
- `guard-prod-actions` prompts on `git push`, `gh release create`, and `npm`/`pnpm publish`. Those prompts are the confirmation steps: run them as separate commands, never chained to save prompts.
