---
name: git-commits
description: ALWAYS invoke before running `git commit` or any commit-related git work when the repository context is non-`.jj/`. In repositories containing `.jj/`, invoke this skill only for explicit Git-only commit intent; do not use it for generic commit intent. Triggers include "commit it", "commit this", "let's commit", "let's re-commit", "continue with the commit", "go ahead and commit", "check it in", "check this in", "ship it", "save it", "stage and commit", "amend that", "fixup", "write a commit message", "what should the commit say", and "draft a commit message" when routing resolves to Git. Also use when writing or rewriting commit messages anywhere — including in implementation plans, design documents, or other artifacts — staging changes, splitting bundled work into separate commits, curating branch history, rebasing, autosquashing, addressing review feedback with fixup commits, or evaluating whether a commit is bisectable for Git flows. Personal defaults for commit-level git work — invoke even when you think you remember the conventions; the skill body has the authoritative rules.
---

# Git Commits & History

Personal defaults for commit-level git work. If project-specific instructions mandate a different workflow, follow the project.

## Routing

Local constraint: in `.jj` repos, invoke only for explicit Git-only commit intent. Generic `.jj` commit intent routes to `jujutsu` + `jj-commits` instead.

## Commit messages

Follow the [seven rules of commit messages](https://cbea.ms/git-commit):

- Imperative mood in subject ("Add feature" not "Added feature")
- Limit subject to 50 characters (72 hard limit), no trailing period
- Separate subject from body with blank line; wrap body at 72 characters
- Subject lines name the change at a high level of abstraction — this aids navigation and is fine. Bodies explain WHY: motivation, constraints, and context the diff lacks.
- Never narrate implementation detail the diff already shows. If the message would become redundant with `git show`, it is too low-level. "Fix session timeout under high load" is a good subject; "Add `last_event_time` field to `SessionStatus` dataclass, initialized via `__post_init__` to `start_time`" is diff narration.

Subjects describe the change, not the workflow event that produced it. Replace "Fix tests", "Address review", or "Continue work on X" with descriptions of the actual code change.

For commit message bodies longer than two sentences, invoke the clean-prose skill before finalizing. Subject lines and one-line bodies don't need it.

## History

The merged history is the project's narrative: what changed and why, told in logical steps. Optimize for the future reader running `git log`, `git blame`, or `git bisect`, not the chronology of how you wrote the code.

- One logical change per commit. A commit is the unit of revert, review, and bisect.
- **Bisectability:** every commit on the trunk should build and pass tests on its own. This is the falsifiable test for whether a commit is well-formed.
- A branch is a reviewable patch series, not a bag of commits. If the series doesn't tell a coherent story when the PR opens, restructure it first.
- During development, commit freely (WIPs, dead ends, fixups). Before pushing for review, curate the series via interactive rebase, autosquash, or `git absorb`.
- Commit each logical change as soon as it's complete rather than batching unrelated changes into one editing session. If bundling happens anyway and `git add -p` is unavailable (no TTY, agent context), split via reset-and-redo: back up the working file, `git checkout HEAD -- <path>`, re-apply the edits in commit-aligned groups, and commit between phases.
- Address review feedback with `git commit --fixup=<sha>`, then `git rebase -i --autosquash` before merge. Do not merge a branch that still contains `fixup!` or "address review" commits.
- For stacked branches in git, use `git-assembler` to ripple rebases through dependent branches when a base branch is curated. (jj handles this natively when working in a jj repo.)
- Do not rebase published history. Force-pushing your own review branch after curation is fine; force-pushing trunk or someone else's branch is not.

## Merge style

- Default: rebase-merge or fast-forward a curated series. Do not squash-merge.
- Squash is acceptable only when the curated series would have been one logical commit anyway. At that point squash and rebase-with-cleanup produce the same result.

## Mechanics

- Always use explicit `git add` with specific file paths; never `git add -A`, `git add .`, or `git add -u` without listing files.
- Before staging, run `git status`. If files you're about to modify already have unstaged or staged work, surface it before proceeding rather than mingling unrelated changes into your commit.
- Verify edits actually succeeded before committing; check `git diff` if uncertain.
- Before committing, run `git diff --cached` and confirm the staged diff contains only the changes you intended. If pre-existing work has been staged alongside, separate it with `git restore --staged <path>`, `git stash --keep-index`, or `git add -p` before committing.
- Before pushing for review, run `git log <base>..HEAD` (where `<base>` is the merge target, usually `main` or `origin/main`) and read the series. Each subject describes a code change rather than a workflow event; bodies explain why the change exists rather than narrating implementation detail (a common autosquash and agent artifact); no `fixup!` or `squash!` commits remain; the order tells a coherent story. If any check fails, curate before pushing.

## Claude Code: sandbox and agent sockets

The sandbox blocks Unix socket connections to authentication agents. `git commit` reaches `gpg-agent` for signing; `git push` reaches `ssh-agent` for SSH key auth. Both require `dangerouslyDisableSandbox: true`. Configure Bash permissions to auto-allow `git commit` and `git push` if you want to avoid the prompts.
