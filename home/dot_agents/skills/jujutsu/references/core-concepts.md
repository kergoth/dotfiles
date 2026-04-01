# Core Concepts

## Mental Model

- The working copy is a commit, addressed as `@`.
- There is no staging area. New and modified files are snapshotted into the working-copy commit by most `jj` commands.
- Commits are routinely rewritten. That is normal, not exceptional.
- Change IDs are stable across rewrites. Commit IDs are not.
- Bookmarks are the Git-facing movable names that correspond most closely to branches.

## Terms To Prefer

| Git-ish term | jj term |
| --- | --- |
| branch | bookmark |
| worktree | workspace |
| reflog | operation log |
| detached HEAD | normal anonymous state |
| staging area / index | none; use commits and file movement commands |

## High-Value Revision Syntax

- `@` means the current working-copy commit.
- `@-` means the parent of `@`.
- `@--` means the grandparent.
- `@+` means a child.
- `main::@` means the range from `main` through `@`.
- `x | y` is union.

Do not assume Git syntax such as `@~1` or `HEAD^`.

## Recovery Mindset

- `jj undo` reverts the last operation.
- `jj op log` shows repository-wide operations, not just one ref moving.
- `jj op restore` can restore an earlier repository state.

Prefer these over destructive Git recovery patterns.

## Read Next

- Read `operational-guide.md` for concrete command flows.
- Read `git-interop.md` for colocated vs non-colocated behavior.
- Read `workspaces.md` for the worktree analogue.
