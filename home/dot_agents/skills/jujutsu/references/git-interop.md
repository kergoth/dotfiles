# Git Interop

## Repo Modes

### Colocated

A colocated workspace has both `.jj/` and `.git/` in the working copy.

Use this when reasoning about the repo:
- jj and Git share the same working copy.
- Call this repo state `colocated` explicitly when explaining it to the user.
- Mixing `jj` and `git` commands is allowed.
- `jj` should still be the default for mutations and history editing.
- Git may observe a detached `HEAD` because jj does not center workflows on one checked-out branch.

### Non-Colocated

A non-colocated jj workspace may show only `.jj/`.

Use this when reasoning about the repo:
- still prefer `jj`
- remote sync still happens through `jj git ...`
- if external Git state must be synchronized explicitly, look for `jj git import` and `jj git export`

## When Git Is Usually Fine

- Read-only inspection such as `git show`, `git diff`, or `git branch` in a colocated repo.
- Tooling that expects `.git/` to exist in a colocated repo.
- Explicit Git-only workflows requested by the user.

Note: `jj git import` and `jj git export` are disabled by default in colocated
workspaces as of 0.44.0. They had a race condition and usually did nothing in
colocated repos (jj handles import/export automatically). Do not suggest running
them explicitly in a colocated workspace.

## When jj Should Lead

- Creating, editing, splitting, squashing, abandoning, or rebasing commits.
- Managing bookmarks.
- Recovering from mistakes.
- Creating extra working copies.

## Git-Backed Setup Notes

- `jj git init` and `jj git clone` create Git-backed jj repos.
- Colocation is the default for Git-backed workspaces in current docs.
- `jj git colocation status|enable|disable` manages colocation state.
- `jj git init --colocate` now refuses to run inside a Git worktree as of `0.38.0`.

## Ref Syntax (0.43.0+)

Git-like ref symbols such as `refs/heads/main` or `refs/tags/v1.0` no longer
resolve to revisions. Always use the plain bookmark name (`main`) or the
`<name>@<remote>` form (`main@origin`) in revsets and `-r` arguments. Teaching
or emitting git-style ref paths is wrong from 0.43.0 onward.

## Tags (0.44.0+)

Tags now work like bookmarks. `jj git fetch` fetches tags as `<name>@<remote>`
and automatically creates tracked local tags of the same name. `jj git push
--all` pushes all tags in addition to bookmarks. Use `jj tag track` and
`jj tag untrack` to manage tracking state (analogous to `jj bookmark
track`/`untrack`). `jj git clone --fetch-tags` is removed; use `--tag=PATTERN`
to filter which tags are fetched.

## Bookmark Reality

- Git pushes usually happen through bookmarks, not anonymous revisions.
- In colocated repos, say `colocated` explicitly before explaining bookmark-based push flow.
- Before pushing, ensure the intended bookmark exists and points to the desired revision.
- Newer jj versions also provide `jj bookmark advance` for moving bookmarks forward.

## Read Next

- Read `workspaces.md` for the worktree analogue.
- Read `version-notes.md` for release-specific behavior changes.
