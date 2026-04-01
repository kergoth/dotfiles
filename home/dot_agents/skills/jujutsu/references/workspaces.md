# Workspaces

## What They Are

`jj workspace` is the jj-native answer to Git worktrees.

A workspace is another working copy backed by the same repository state. Each workspace can have a different commit checked out.

## Core Commands

- `jj workspace add <path>`
- `jj workspace list`
- `jj workspace root`
- `jj workspace root --name <workspace>`
- `jj workspace forget <workspace>`
- `jj workspace update-stale`

## When To Reach For Them

- Keep one workspace on a long-running test or experiment.
- Continue normal development in another workspace.
- Avoid forcing Git worktree assumptions into a jj repo.

## Stale Working Copies

A workspace becomes stale when its files no longer match the operation state jj expects, often because another workspace rewrote the working-copy commit.

Use:
- `jj workspace update-stale`

This updates the workspace and may create a recovery commit if needed.

## Release Notes That Matter

- `0.38.0`: `jj workspace root` gained `--name`.
- `0.39.0`: `jj workspace add` now links with relative paths, which matters for moved repos and containers.

## Read Next

- Read `git-interop.md` for colocated behavior.
- Read `operational-guide.md` for normal day-to-day workflows.
