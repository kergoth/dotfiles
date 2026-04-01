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

## Bookmark Reality

- Git pushes usually happen through bookmarks, not anonymous revisions.
- In colocated repos, say `colocated` explicitly before explaining bookmark-based push flow.
- Before pushing, ensure the intended bookmark exists and points to the desired revision.
- Newer jj versions also provide `jj bookmark advance` for moving bookmarks forward.

## Read Next

- Read `workspaces.md` for the worktree analogue.
- Read `version-notes.md` for release-specific behavior changes.
