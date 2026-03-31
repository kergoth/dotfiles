---
name: find-session
description: >
  Find and resume a past Claude Code conversation by searching session JSONL history files
  by keyword. Use this skill whenever the user wants to find a previous conversation, can't
  remember which directory they were working in, wants to look up work from a past session,
  needs to resume a session they can't locate with /resume, or says something like "I know
  we discussed X somewhere" or "where was that session about Y". Infers search scope and
  keywords from the user's description and presents matching sessions with AI-generated
  summaries before asking which to resume. Always use this skill rather than manually
  searching ~/.claude/ yourself.
---

# Find Session

Search past Claude Code session history by keyword and present matching sessions for resumption.

## Step 1: Infer scope and extract keywords

From the user's description:

**Scope:**
- "in this project" / "here" / "in this repo" / "in this directory" → `--scope project`
- "somewhere" / "I can't remember" / "I was working on X" / no location specified → `--scope global`
- When ambiguous, default to `--scope global`

**Keywords:** Extract 2–4 specific, concrete terms. Prefer domain nouns over generic verbs.
- "that session about the marketplace proposal" → `marketplace proposal`
- "where we set up the mender deployment" → `mender deploy`

## Step 2: Run the search script

```bash
python ~/.claude/skills/find-session/scripts/search_sessions.py \
  --scope <project|global> \
  --depth quick \
  --cwd "$(pwd)" \
  [--exclude <session_id>] \
  <keyword1> [keyword2 ...]
```

The script outputs a JSON array (max 10 results, most-recent-first). Read the output directly. If you need to filter, slice, or extract fields, pipe to `jq` — never pipe through `python`, `python3`, or write intermediate files.

If a result is clearly the current session (the one you're running in right now), re-run with `--exclude <session_id>` to drop it from results. `--exclude` is repeatable.

**Output schema** (one object per session):
```
{
  "session_id":      string,           // UUID
  "session_name":    string | null,    // first user message or null
  "project_dir":     string,           // absolute path to project cwd
  "first_timestamp": string,           // ISO8601
  "last_timestamp":  string,           // ISO8601
  "first_exchanges": [                 // up to 1 (quick) or 3 (thorough)
    { "user":      {role, text, timestamp},
      "assistant": {role, text, timestamp} | null }
  ],
  "last_exchanges":  [...],            // same structure, from end of session
  "match_contexts":  [                 // one entry per non-overlapping keyword hit
    { "match":          {role, text, timestamp},
      "context_before": [{role, text, timestamp}, ...],
      "context_after":  [{role, text, timestamp}, ...] }
  ]
}
```

## Step 3: If no results, retry at thorough depth

```bash
python ~/.claude/skills/find-session/scripts/search_sessions.py \
  --scope <project|global> \
  --depth thorough \
  --cwd "$(pwd)" \
  <keyword1> [keyword2 ...]
```

If still no results: tell the user and suggest trying different or fewer keywords.

## Step 4: Summarize and present

For each session write a short (≤10 word) summary label. Present as a table, sorted
most-recent-first (the script already sorts this way):

```
Found N sessions matching "<keywords>":

#  Date        Project          Summary
1  2026-03-30  mobile-system    Pano-first capture cycle design sync
2  2026-03-26  mobile-system    Steps after pano/dc swap
3  2026-03-25  mobile-system    Mobile systems power modes proposal

Which session?
```

**Date:** `YYYY-MM-DD` from `last_timestamp`.
**Project:** `basename(project_dir)`.
**Summary:** derive from `first_exchanges` and `last_exchanges`; include `session_name`
if present and not a bare UUID.

## Step 5: Provide resume command

**Wait for the user to reply with a number before doing anything else.**

Once the user picks a number, show:

```bash
cd <project_dir> && claude --resume <session_id>
```
