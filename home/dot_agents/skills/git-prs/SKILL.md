---
name: git-prs
description: Use when opening pull requests, drafting or revising PR descriptions, addressing PR review feedback, updating an existing PR after a force-push or rebase, handling PR templates, or working with GitHub pull requests, GitLab merge requests, or Bitbucket pull requests. Covers personal defaults for PR description hygiene and reviewer-facing content. Invoke this skill before running `gh pr create`, `glab mr create`, or equivalent, even on terse requests like "open a PR", "send a PR", "ship the PR", "PR it", "push it up for review", or "make an MR" — those phrases all map to the activities above.
---

# Pull Requests

Personal defaults for pull request work. If a project's CONTRIBUTING, AGENTS.md, or CLAUDE.md mandates a different workflow, follow the project.

## Before creating a PR

Check `.github/pull_request_template.md` and `.github/PULL_REQUEST_TEMPLATE.md`. If a template exists, the PR body must follow its structure.

Invoke the `clean-prose` skill before finalizing the PR description.

## Description hygiene

- Remove or replace any placeholder text that would render in the PR body (for example, "type your description here") so the submitted description contains actual content rather than author instructions. Strip HTML comments and template scaffolding (for example, `<!-- replace this with X -->`); these don't render on GitHub but keep the description clean for future edits and copy-paste.
- Do not restructure an existing PR description to match the repository's PR template when the original does not already follow it; reformatting risks losing context the author captured. Surface the mismatch and let the user choose whether to reshape it. Updating the description to track the branch contents within its existing shape is the right move.

## Checkboxes

- Checkboxes that ask the human to acknowledge they reviewed, tested, or approved the work stay unchecked. The agent did not perform those acts; that acknowledgement belongs to the human.
- Checkboxes that describe how the work was produced (e.g., "made with AI assistance", "co-authored by an AI agent") must be checked accurately when they apply. Leaving an AI-assistance box unchecked when AI was used is misleading and is not acceptable.

## After updating an existing PR

After a force-push, additive commits, or rebase, re-read the PR description with `gh pr view` and compare it against the new branch contents. If the description no longer matches the diff (added or removed scope, changed approach, stale file lists), update it via `gh pr edit`. Description-versus-diff drift is a review hazard.
