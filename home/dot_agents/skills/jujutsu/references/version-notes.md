# Version Notes

## Baseline

This skill is intentionally versioned.

- Validated against jj `0.39.0`
- Reviewed on 2026-03-12
- Sources reviewed:
  - local docs under `jj/docs/`
  - local docs under `jj/cli/docs/`
  - release notes for `v0.38.0`
  - release notes for `v0.39.0`

## Refresh Rule

Update this skill when any of the following is true:
- the installed `jj --version` is newer than `0.39.0`
- upstream release notes introduce command, workflow, or safety changes that affect agent behavior
- local docs contradict the current skill guidance

If the installed `jj` is older than `0.39.0`, do not fork the whole skill by version. Instead, verify drift-prone commands with `jj help ...` and treat the skill as a documented baseline until there is evidence that an older-version incompatibility matters in practice.

When updating:
1. review the new release notes
2. update this file first
3. adjust `SKILL.md` only if the immediate guidance changed
4. update any affected reference file

## Impactful Changes In 0.38.0

- Per-repo and per-workspace config moved outside the repo for security reasons. Do not teach `.jj/repo/config.toml` or `.jj/workspace-config.toml` as current defaults.
- `jj workspace root` gained `--name`.
- `jj git init --colocate` now refuses to run inside a Git worktree.
- `jj git push --bookmark <name>` automatically tracks the bookmark if needed.

## Impactful Changes In 0.39.0

- `jj bookmark advance` was added and can replace older `jj tug`-style advice.
- `jj workspace add` now uses relative links, improving moved-repo and container behavior.
- `jj undo` output is more descriptive.
- `jj op undo` was removed; teach `jj undo`, `jj redo`, or `jj op revert` instead.
- `jj util snapshot` is the supported snapshot command going forward.

## Current Guidance Boundaries

If a future release changes any of these, revisit the skill:
- bookmark movement and push semantics
- workspace creation and stale-update behavior
- colocation defaults
- non-interactive alternatives for split, resolve, or snapshot workflows
