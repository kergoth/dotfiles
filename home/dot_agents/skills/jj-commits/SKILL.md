---
name: jj-commits
description: Use for generic commit-related intent in `.jj/` repositories. Must be paired with `jujutsu` in the same turn; never use it as a standalone skill. Explicit Git-only `.jj` commit intent routes to `git-commits`.
---

# JJ Commits

Commit-policy defaults for jj repositories.

Use this skill only for commit-quality and commit-series hygiene in `.jj`
contexts. This skill does not define jj command mechanics.

## Routing

Invoke `jujutsu` in the same turn; it owns jj mechanics and sequencing that this skill does not cover. This skill applies to generic commit intent in `.jj` contexts only; explicit Git-only intent uses `git-commits` instead.

## Scope

This skill owns jj commit policy:

- commit message quality expectations
- one-logical-change-per-commit guidance
- commit-series hygiene before review and merge
- bisectability expectations for curated history

This skill explicitly excludes:

- jj command mechanics
- jj procedural workflows
- jj rewrite sequencing mechanics

Use `jujutsu` for jj mechanics, operation sequencing, and command-level flow.

## Commit messages

Follow the [seven rules of commit messages](https://cbea.ms/git-commit):

- Imperative mood in subject ("Add feature" not "Added feature")
- Limit subject to 50 characters (72 hard limit), no trailing period
- Separate subject from body with blank line; wrap body at 72 characters
- Explain WHY in the body, not WHAT (the diff shows what changed)

Subjects describe the change, not the workflow event that produced it. Replace "Fix tests", "Address review", or "Continue work on X" with descriptions of the actual code change.

For commit message bodies longer than two sentences, invoke the clean-prose skill before finalizing. Subject lines and one-line bodies don't need it.

## Commit-Series Hygiene

Treat the branch as a coherent patch series:

- each commit should represent one logical change
- each commit should be bisectable against repository expectations
- commit order should tell a coherent narrative for reviewers

During development, temporary commits are acceptable. Before review, curate the
series into clear logical steps and remove workflow-noise commits.

Before pushing for review, run `jj log -r '<base>..@'` (where `<base>` is the merge target, e.g., `main`) and read the series. Each subject describes a code change; bodies explain why; no temporary or workflow-noise commits remain; the order tells a coherent story. If any check fails, curate before pushing.
