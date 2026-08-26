---
name: git-commits
description: >-
  Use for commit-level Git workflows in non-`.jj/` repositories: stage one
  logical change, write or revise commit messages, amend, create fixup
  commits, split bundled edits, curate history with rebase or autosquash, and
  verify bisectability. In repositories containing `.jj/`, use this skill only
  for explicit Git-only commit intent; generic commit intent routes to
  `jujutsu` plus `jj-commits`. Trigger on requests such as "commit this",
  "check it in", "ship it", "stage and commit", "amend", "fixup", "clean up
  history", "reword/split commits", or "draft/rewrite the commit message". Also
  use for indirect commit-message creation when drafting plans that specify
  commits (including `superpowers:writing-plans` outputs), and when writing
  commit message text in design docs, PR notes, or other artifacts.
---

# Git Commits & History

Personal defaults for commit-level git work. If project-specific instructions mandate a different workflow, follow the project.

## Routing

Local constraint: in `.jj` repos, invoke only for explicit Git-only commit intent. Generic `.jj` commit intent routes to `jujutsu` + `jj-commits` instead.

## Commit messages

**Documented convention beats inferred, inferred beats default.** If no CONTRIBUTING/AGENTS.md/CLAUDE.md convention applies, check `git log --oneline` for an established local pattern — scope prefixes (`component: change`), tagging style, subject shape — before applying the defaults below, and match it if one exists. A subject that breaks a repo's own established shape is harder to scan against its own history, even where it satisfies every rule below on its own terms.

Follow the [seven rules of commit messages](https://cbea.ms/git-commit):

- Imperative mood in subject ("Add feature" not "Added feature")
- Limit subject to 50 characters (72 hard limit), no trailing period
- Separate subject from body with blank line; wrap body at 72 characters
- Subject lines name the change at a high level of abstraction — this aids navigation and is fine. Bodies explain WHY: motivation, constraints, and context the diff lacks.
- Never narrate implementation detail the diff already shows. If the message would become redundant with `git show`, it is too low-level. "Fix session timeout under high load" is a good subject; "Add `last_event_time` field to `SessionStatus` dataclass, initialized via `__post_init__` to `start_time`" is diff narration.

**Prefer goal/behavior over mechanism in the subject.** Name what changed, not the implementation reached for, unless the mechanism itself is the change (a migration, a protocol swap). Test: what would you `grep` history for later? "Load rules from an external TOML config" names the vehicle; "Externalize tagging rules from the public script" names the reason.

Subject and body alike: describe the change, not the workflow event that produced it. Subject: replace "Fix tests", "Address review", "Continue work on X" with the actual code change. Body: cut narration of how the change was found ("Noticed while debugging X...", "Discovered mid-session that..."), even before a real WHY sentence. State the motivation directly, skip the lead-up.

**Body-echoes-subject is not a body.** A body that merely rephrases the subject in past tense conveys nothing and is a strong AI-generation signal. Delete it or replace it with actual motivation:

```
# Bad — body adds no information
Update README with Paper Atlas Tool details

Added Paper Atlas Tool details to the README.

# Good — body explains why the change exists
Document Paper Atlas Tool setup in README

The tool ships as a sidecar beside the game exe; without setup
instructions users won't know to configure the dump/replacement
folders before first run.
```

**Bodies must be self-contained.** "The fix", "that issue", "this problem" lean on context only the current conversation has. A reader six months out via `git blame` has none of it. Restate the concrete problem instead of pointing at it: not "documents the fix in more detail", but "the sandbox blocks the gpg-agent/ssh-agent sockets signed commits need".

**Avoid "Update X with Y" subject construction.** Using `with` as a connector ("Update README with details on X") obscures intent and makes every commit look identical at a glance. Prefer a verb that names the actual change: "Document X in README", "Explain X setup", "Clarify X behavior", "Remove Y from Z".

For commit message bodies longer than two sentences, invoke the clean-prose skill before finalizing. That pass is what catches jargon-heavy bodies that still pass the structural checks below. Subject lines and one-line bodies don't need it.

**Commit message input:** Do not trust `git commit -m` to format body text.
Git stores each message argument exactly as passed; it never wraps long lines.
For any body longer than one short line, write a temporary message file, verify
line lengths with `awk '{ print length, $0 }'`, then commit with
`git commit -F <absolute-path>`. Use the same absolute path when creating and
committing the file; do not rebuild it from `$TMPDIR`, because sandboxed and
unsandboxed shells may see different temp directories.

## History

The merged history is the project's narrative: what changed and why, told in logical steps. Optimize for the future reader running `git log`, `git blame`, or `git bisect`, not the chronology of how you wrote the code.

- One logical change per commit. A commit is the unit of revert, review, and bisect.
- **Bisectability:** every commit on the trunk should build and pass tests at that commit, not just at HEAD — the falsifiable test for whether a commit is well-formed. Two quiet failure modes: a commit referencing something a *later* commit introduces (forward reference, e.g. docs naming tools before they're registered), and tests batched into a final commit instead of landing with the code they cover — each earlier commit "passes" only because nothing yet exercises the new code, not because it works, so a regression goes uncaught until the batch commit.
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
- After committing or amending, verify the final commit message before reporting success. Check subject length, body wrapping, blank-line structure, self-contained body content, and absence of workflow narration. If the body is more than two sentences, confirm the clean-prose skill was applied. Reciting the patch's field and flag names is not a WHY; keep a name only when it is the distinction the reader needs (which lock, which path, which silent-failure flag). If any check fails, amend immediately.
- Before pushing for review, run `git log <base>..HEAD` (where `<base>` is the merge target, usually `main` or `origin/main`) and read the series. Each subject describes a code change rather than a workflow event; bodies explain why the change exists rather than narrating implementation detail (a common autosquash and agent artifact); no `fixup!` or `squash!` commits remain; the order tells a coherent story. If any check fails, curate before pushing.

## Claude Code: sandbox and agent sockets

The sandbox blocks Unix socket connections to authentication agents. `git commit` reaches `gpg-agent` for signing; `git push` reaches `ssh-agent` for SSH key auth. Both require `dangerouslyDisableSandbox: true`. Configure Bash permissions to auto-allow `git commit` and `git push` if you want to avoid the prompts.

## Codex: sandbox and agent sockets

The sandbox blocks Unix socket connections to authentication agents. `git commit` reaches `gpg-agent` for signing; `git push` reaches `ssh-agent` for SSH key auth. Both require shell escalation with `sandbox_permissions: "require_escalated"` when signing or SSH auth is required. Use a focused command approval for `git commit` or `git push`; don't allowlist `~/.gnupg/` or `~/.ssh/`.
