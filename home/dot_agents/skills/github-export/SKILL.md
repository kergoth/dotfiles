---
name: github-export
description: Use when working with GitHub issues, PRs, or discussions in any repo
  that may have a local github-data/ export. Before making gh API calls for any
  bulk or analysis task (triage, pattern scanning, cross-issue queries, event
  handling), check for github-data/repo.yml — if present and fresh enough, prefer
  local file reads and grep over API calls. Also use when handling the events/
  directory for agent-driven maintenance, or when deciding whether to run a sync
  before starting analysis work.
---

# Using Local GitHub Data (github-export)

The `github-export` tool syncs GitHub issues, PRs, discussions, releases, labels,
milestones, and Projects v2 into `github-data/` as plain markdown. When present,
agents read and reason about GitHub content without any API calls.

## Detect and Check Freshness

```bash
cat github-data/repo.yml   # look at synced_at
```

What "fresh enough" means depends on the task:
- Triage, pattern analysis, scoring: hours to a day is fine
- Real-time state of a specific item: use `gh` unless synced within the last hour
- Cross-issue analysis tolerates staleness well — content changes slowly

If absent or too stale, sync first:
```bash
github-export owner/repo                 # sync into github-data/ in current dir
github-export --max-age=6mo owner/repo  # scope first sync of large repos
```
Requires `GITHUB_TOKEN` or `gh auth login` (token picked up automatically from `gh`).

## Decision: Local Files vs API

| Task | Prefer |
|------|--------|
| Read many issues/PRs for analysis or scoring | Local files |
| Find issues by label, state, author, keyword | grep |
| Cross-reference issues ↔ PRs | grep |
| Check real-time state of one specific item | `gh issue/pr view` |
| Post comments, merge, close, label | `gh` (writes always go through API) |

## File Layout

```
github-data/
  repo.yml               # metadata + synced_at
  labels.yml
  milestones.yml
  issues/0042.md         # one file per issue or PR — full thread
  discussions/0007.md
  projects/0001.md
  releases/v1.0.0.md
  events/                # agent handoff: read → act → delete
```

Each issue file has YAML frontmatter (number, title, state, labels, assignees,
milestone, PR-specific fields) followed by the full chronological thread —
comments, reviews, and events — as multi-document YAML separated by `---`.

## Common Grep Patterns

```bash
# All open issues
grep -rl "^state: open" github-data/issues/

# Open bugs
grep -l "state: open" github-data/issues/*.md | xargs grep -l "  - bug"

# Merged PRs to main
grep -l "target_branch: main" github-data/issues/*.md | xargs grep -l "merged: true"

# Open PRs awaiting review
grep -l "type: pull_request" github-data/issues/*.md | xargs grep -l "state: open"

# Issues mentioning a term
grep -rl "search term" github-data/issues/
```

## Event Files

Events in `github-data/events/` represent individual changes detected since the
last sync. Filenames sort chronologically: `20260903-224919-018-issue_created-130.md`.
The timestamp prefix makes date-based filtering straightforward.

Event frontmatter fields: `event`, `number`, `title`, `author`, `state`, `labels`,
`file` (path to the full issue file), `repo`, `url`, `exported_at`.

Event types include `issue_created`, `issue_closed`, `pr_created`, `pr_merged`,
`pr_closed`, `comment_created`, `pr_review_requested`, `pr_reviewed`,
`discussion_created`, and others.

**How to use them depends on the task:**

- **Maintenance workflow** — run a sync on a schedule, then read recent event
  files to see what needs attention, read the linked issue file for context,
  act with `gh`, delete handled events once done.
- **Incremental triage**: filter events by date to find which issues have been
  updated since the last triage run, then prioritize re-scoring those.
- **General awareness**: `ls github-data/events/` to see what has changed recently
  without committing to any particular action.

Filter by date using the filename prefix — no need to read all files when only
recent changes matter:
```bash
# Events since yesterday
ls github-data/events/20260904-* github-data/events/20260905-* 2>/dev/null

# Events by type
ls github-data/events/*-issue_created-*.md
```
