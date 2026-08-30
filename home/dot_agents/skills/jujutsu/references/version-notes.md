# Version Notes

## Baseline

This skill is intentionally versioned.

- Validated against jj `0.44.0`
- Reviewed on 2026-08-30
- Sources reviewed:
  - local docs under `jj/docs/`
  - local docs under `jj/cli/docs/`
  - release notes for `v0.38.0`
  - release notes for `v0.39.0`
  - release notes for `v0.40.0`
  - release notes for `v0.41.0`
  - release notes for `v0.42.0`
  - release notes for `v0.43.0`
  - release notes for `v0.44.0`

## Refresh Rule

Update this skill when any of the following is true:
- the installed `jj --version` is newer than `0.44.0`
- upstream release notes introduce command, workflow, or safety changes that affect agent behavior
- local docs contradict the current skill guidance

If the installed `jj` is older than `0.44.0`, do not fork the whole skill by version. Instead, verify drift-prone commands with `jj help ...` and treat the skill as a documented baseline until there is evidence that an older-version incompatibility matters in practice.

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

## Impactful Changes In 0.40.0

- `jj op show`, `jj op diff`, `jj op log -p` now filter to "interesting"
  revisions by default (controlled by `revsets.op-diff-changes-in`). Use
  `--show-changes-in=all` to see everything, as before.
- `jj op log` now includes the workspace name in each operation entry.
- New revset functions `diff_lines_added()` and `diff_lines_removed()` for
  matching commits by content on one side of a diff.
- `WorkspaceRef` templates gained a `.root()` method (useful in template
  customization; not a breaking change to agent workflows).

## Impactful Changes In 0.41.0

- New global flag `--no-integrate-operation`: runs a command without
  recording the resulting operation into the op log. Distinct from
  `--ignore-working-copy`, which avoids snapshotting but still records the
  op. Prefer `--ignore-working-copy` for lightweight read queries; use
  `--no-integrate-operation` only when hiding the op from the log is
  intentional.
- `jj git push --all/--tracked/-r REVSETS` no longer fails when bookmarks
  have private commits or conflicts; ineligible bookmarks are silently
  skipped instead. Agents that relied on the error to detect partial pushes
  must now check push output explicitly.
- `jj file search --pattern` default changed from `glob:` to `regex:`.
  Scripts passing bare patterns without a `kind:` prefix now execute as
  regex, not glob.
- `jj git clone` bookmark patterns are now stored in jj's repo settings
  file instead of `.git/config`. Agents inspecting `.git/config` post-clone
  will not find these values there.
- `JJ_PAGER` env var now overrides `ui.pager` (analogous to `JJ_EDITOR`).
- `remotes.<name>.fetch-bookmarks` and `remotes.<name>.fetch-tags` config
  options control which bookmarks/tags are fetched by default from a remote.

## Impactful Changes In 0.42.0

- Removed deprecated command options:
  - `jj commit --reset-author`/`--author`
  - `jj describe --no-edit`/`--edit`/`--reset-author`/`--author`
  - `jj git push --allow-new`
  - `jj metaedit --update-committer-timestamp`
- Removed deprecated config options: `git.auto-local-bookmark` and
  `git.push-new-bookmarks`. Do not teach these config keys.
- `jj show` now accepts multiple revisions (shows them in sequence).
- `jj git fetch` now generates evolution history from change IDs, so local
  descendant revisions are rebased when the remote rewrites a parent.

## Impactful Changes In 0.43.0

- Git-like ref symbols (`refs/heads/main`, etc.) are no longer resolved to
  revisions. Always use the bookmark name (`main`) or `<name>@<remote>` form.
  Teaching git-style ref paths in revsets or `-r` arguments is now wrong.
- `jj bookmark track`/`untrack` no longer accepts `<kind>:<bookmark>@<remote>`
  patterns. Plain `<bookmark>@<remote>` syntax is still supported.
- `git_head()` and `git_refs()` revset/template functions have been removed.
  Do not suggest these.
- `ui.revsets-use-glob-by-default` config option has been removed.
- New command: `jj run <command> [-r REVSET]` — runs a command over each
  revision in the revset, each with a private working copy. Useful for
  `cargo check`, `cargo fix`, test runs, etc. across a stack.
- New revset function `forks()`: yields commits with more than one child.
- New command: `jj config gc` — deletes configuration for deleted/moved repos
  from `~/.config/jj/repos`.

## Impactful Changes In 0.44.0

- Tags are now fully tracked like bookmarks. `jj git fetch` fetches tags as
  `<name>@<remote>` and automatically tracks them with local tags.
- `jj git push --all` now pushes all tags in addition to bookmarks.
- `jj git clone --fetch-tags=all|none|included` is removed; use `--tag=PATTERN`.
- `jj tag track` and `jj tag untrack` are new commands (analogous to
  `jj bookmark track`/`untrack`).
- `jj git push` gained `--allow-conflicts` to push commits containing conflicts.
- `jj file search` now prints each matched line prefixed by file path, rather
  than only listing files. Use `--name-only` for the old file-listing behavior.
- `jj git import` and `jj git export` are disabled by default in colocated
  workspaces. These commands usually did nothing in colocated repos; direct
  mutation now goes through `jj` commands as intended.
- `jj workspace list` now shows workspace roots by default (output
  customizable with `templates.workspace_list` or `-T`).
- New revset alias `builtin_log()` resolves to the built-in default log set.
  Custom `revsets.log` configs can call `builtin_log()` instead of copying
  the expression.
- `merge_point()` revset function added (like `fork_point()` but for merges).
- `jj absorb --interactive`/`-i` added, but prefer non-interactive flows for
  agents.
- Passing a flag more than once no longer errors; last value wins.
- Behavior when `@` becomes immutable has stabilized: jj now creates a new
  working-copy revision immediately, closer to pre-0.43 behavior. Agents
  that observed different handling across 0.43 should re-test on 0.44.

## Current Guidance Boundaries

If a future release changes any of these, revisit the skill:
- bookmark movement and push semantics
- workspace creation and stale-update behavior
- colocation defaults
- non-interactive alternatives for split, resolve, or snapshot workflows
