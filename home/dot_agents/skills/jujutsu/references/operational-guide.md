# Operational Guide

## Start Work

1. Run `jj st`.
2. Run `jj log` if the stack shape matters.
3. If `@` already contains unrelated work, create a fresh working-copy commit with `jj new`.
4. Set or update the description with `jj desc -m "Message"`.

## While Editing

- Use `jj diff` to inspect the current working-copy change.
- Use `jj show @` when you want the current commit plus metadata.
- Prefer change IDs when selecting other revisions.

## Refine Commits

- Keep editing `@` if the current change is still the same logical unit.
- Use `jj squash` to move the working-copy change into its parent.
- Use `jj absorb` when small fixes should flow back into earlier commits in the stack.
- Use `jj edit <rev>` to resume editing an existing change.

## Split Without Assuming Interactivity

Prefer non-interactive `jj split` by path when the split boundary is clear.

Examples:
- `jj split path/to/file`
- `jj split file1 file2`
- `jj split -r <rev> file1 file2`

Interactive `jj split` is available, but it is a poor default for agents.

If the change does not divide cleanly by path:
1. Inspect the current state with `jj diff`.
2. Prefer documenting that the split is hunk-based and may require an interactive tool or a more careful manual rewrite.
3. Only fall back to restore-based surgery when you can state exactly which revision is the source and target for `jj restore --from F --to T`, and verify the result immediately with `jj diff` and `jj log`.

Do not give hand-wavy advice like "restore some changes and reapply them later" without naming the source revision, target revision, and verification step.

## Push And Fetch

- Fetch with `jj git fetch`.
- Push with `jj git push --bookmark <name>`.
- Before pushing, confirm the bookmark target with `jj bookmark list` or `jj log`.
- If needed, move or create the bookmark first.

## Conflicts

- `jj` can materialize conflicts in the working copy with markers.
- For agent use, prefer editing conflicted files directly when practical.
- Use `jj resolve` only when an interactive merge-tool flow is acceptable.
- After resolving, inspect with `jj diff` and verify status with `jj st`.

## Agent-Specific Cautions

- Prefer `-m` flags instead of opening an editor.
- Avoid assuming TUIs are acceptable just because a command supports one.
- Re-run `jj st` after mutating operations to confirm the resulting working-copy state.

## Read Next

- Read `core-concepts.md` for the jj mental model.
- Read `git-interop.md` when Git commands are involved.
- Read `workspaces.md` for multi-working-copy tasks.
