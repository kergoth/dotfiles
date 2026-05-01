---
name: jujutsu
description: Use when working with version control in a repository that contains `.jj/`, or when the user explicitly mentions Jujutsu or `jj`. When the VCS context is ambiguous, check for `.jj/` in the working tree before defaulting to plain Git. Do not use this skill as the primary route for non-`.jj/` generic Git tasks.
---

# Jujutsu

## Overview

Use this skill to keep VCS behavior accurate in jj repositories. Prefer `jj` for mutations, history editing, bookmarks, workspaces, and recovery. In colocated repositories, Git is still available, but do not default to Git mental models.

Local constraint: for `.jj` commit paths, always pair with `jj-commits` (generic intent) or `git-commits` (explicit Git-only intent).

Validated against jj `0.39.0` on 2026-03-12 using `jj/docs/`, `jj/cli/docs/`, and the `v0.38.0` and `v0.39.0` release notes.

## Detect The Repo First

1. Check whether the current directory or an ancestor contains `.jj/`.
2. If yes, treat the repo as a jj repo and use this skill even if the user asked for generic Git help.
3. If `.jj/` and `.git/` both exist, explicitly describe it as a colocated workspace.
4. If only `.jj/` is present, still prefer `jj`; Git interop may exist behind the scenes, but the workspace is not colocated.
5. If `.jj/` is absent, answer as plain Git. Do not append jj comparisons, translations, or "in jj..." sidebars unless the user explicitly asked for jj or for a Git-vs-jj comparison.

## Immediate Translation Table

| If you reach for Git... | Prefer in jj | Notes |
| --- | --- | --- |
| `git status` | `jj st` | Working copy state and current commit. |
| `git log` | `jj log` | Use revsets instead of Git revision syntax. |
| `git diff` | `jj diff` | Diff the working-copy commit. |
| `git checkout <rev>` | `jj edit <rev>` | Switch the working copy to another revision. |
| `git commit --amend` | keep editing `@`, or `jj squash` | The working copy is already a commit. |
| `git commit` for a new step | `jj new`, then `jj desc -m "..."` | Start a fresh working-copy commit. |
| `git branch` | `jj bookmark` | Bookmarks are the Git-facing movable names. |
| `git rebase` | `jj rebase` | jj rebases descendants automatically after rewrites. |
| `git reflog` | `jj op log` | Repository-wide operation history. |
| `git reset --hard` for recovery | `jj undo`, `jj restore`, `jj op restore` | Prefer reversible recovery tools. |
| `git worktree` | `jj workspace` | Workspaces are the jj-native multi-working-copy model. |
| `git fetch` | `jj git fetch` | Use jj for remote sync unless a Git-only action is needed. |
| `git push` | `jj git push --bookmark <name>` | Ensure the bookmark points where you intend. |
| `HEAD^` / `HEAD~1` | `@-` | Parent of the working-copy commit. |
| `HEAD~N` (N dashes) | `@--`, `@---`, … | Repeat `-` for each ancestor; `@~N` is **not** jj syntax. |
| `main..HEAD` (range) | `main::@` | jj uses `::` for ranges, not `..` or `...`. |

## Operating Rules

- Inspect first with `jj st` and usually `jj log`.
- Prefer non-interactive commands in agent contexts. Use `-m` when available, and avoid editor or TUI flows unless the task explicitly allows them.
- Prefer change IDs over commit IDs when selecting revisions.
- Never write `@~N` for ancestors — that is Git syntax applied to a jj symbol and is not valid. Use `@-` (one ancestor), `@--` (two), `@---` (three), and so on.
- Never write `x..y` or `x...y` for ranges — use `x::y` (jj inclusive range syntax).
- Prefer `jj` for mutations even in colocated workspaces.
- When both `.jj/` and `.git/` exist, use the word `colocated` directly instead of implying it indirectly.
- Use Git mainly for read-only inspection or for an explicitly Git-specific workflow that jj documentation says is safe.
- Treat `jj workspace` as the first answer to "use a worktree".
- Reach for `jj undo` and `jj op log` before destructive recovery ideas.

## Load The Right Reference

- For the jj mental model and revset basics, read `references/core-concepts.md`.
- For common agent workflows, read `references/operational-guide.md`.
- For Git interop and when Git is acceptable, read `references/git-interop.md`.
- For workspaces and stale working copies, read `references/workspaces.md`.
- For release targeting and refresh rules, read `references/version-notes.md`.

## Version Discipline

Before changing this skill for a newer jj release:
- check the local `jj --version` output if available
- review release notes newer than `0.39.0`
- update `references/version-notes.md`
- adjust command guidance only after confirming docs or release notes

If the installed `jj` is older than `0.39.0`, treat command examples as baseline guidance rather than guaranteed syntax and verify drift-prone commands with `jj help ...` before relying on them. If the installed `jj` is newer than `0.39.0`, review newer release notes before assuming the skill is fully current.
