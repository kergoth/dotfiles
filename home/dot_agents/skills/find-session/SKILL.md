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
- "in this project" / "here" / "in this repo" / "in this directory" → `--scope project --cwd "$(pwd)"`
- User names a specific project or repo (e.g. "it was in my-api-project", "in the backend-service repo") → resolve the path (check `~/Workspace/`, `~/Repos/`) and use `--scope project --cwd <resolved-path>`
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
  --cwd <path> \
  [--exclude <session_id>] \
  <keyword1> [keyword2 ...]
```

The script outputs a JSON object with `total_matching` (all files rg found) and `sessions` (up to `--max-results`, default 10, sorted by `match_count` desc then recency). Read the output directly. If you need to filter, slice, or extract fields, pipe to `jq` — never pipe through `python`, `python3`, or write intermediate files.

If a result is clearly the current session (the one you're running in right now), re-run with `--exclude <session_id>` to drop it from results. `--exclude` is repeatable.

**Output schema:**
```
{
  "total_matching": number,            // total files rg matched (may exceed sessions shown)
  "sessions": [
    {
      "session_id":      string,           // UUID
      "session_name":    string | null,    // custom title if set; falls back to first substantive prompt from history.jsonl; null if neither available
      "away_summary":    string | null,    // recap summary stored by Claude Code on session pause; null if none
      "project_dir":     string,           // absolute path to project cwd
      "first_timestamp": string,           // ISO8601
      "last_timestamp":  string,           // ISO8601
      "match_count":     number,           // keyword hit count (relevance signal)
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
  ]
}
```

To fetch thorough context for specific sessions by ID (bypassing keyword search):
```bash
python ~/.claude/skills/find-session/scripts/search_sessions.py \
  --depth thorough \
  --session-ids <id1> --session-ids <id2> \
  <keyword1> [keyword2 ...]
```

## Step 3: If the target isn't in the results

Work through these in order — don't skip to keyword changes until you've exhausted the earlier steps.

### Step 3a: Get thorough context for the top candidates

After every quick search, run a targeted thorough pass on the top candidates (those with the highest `match_count`, typically the top 2–3) before presenting results or drawing any conclusions. Use `--session-ids` so you only read those files — not all 28 matches.

Extract full session IDs from the quick search output — never truncate and then reconstruct:
```bash
# Extract full IDs for the top 3 candidates
<quick_output> | jq -r '[.sessions[:3] | .[].session_id] | join(" ")'
```

**WARNING:** Session IDs are UUIDs. If you only extracted a prefix (e.g., first 8 chars), do NOT attempt to reconstruct the full ID — you will hallucinate the suffix. Either re-extract the full ID from the original output, or pass the prefix directly (`--session-ids` supports unambiguous prefixes).

```bash
python ~/.claude/skills/find-session/scripts/search_sessions.py \
  --depth thorough \
  --session-ids <id1> --session-ids <id2> \
  <same keywords>
```

Thorough widens the context window around each keyword hit (2 messages → 5), which is usually enough to distinguish "this session is about X" from "this session mentioned X in passing." It also gives better first/last exchanges for writing accurate summaries.

A session is **substantive** when keywords appear in the middle of real discussion about the topic. It's **incidental** when keywords only appear in a filename, a path, or a brief aside while working on something else.

Only move on to 3b/3c if thorough contexts still don't identify the right session.

### Step 3b: Cap was applied (total_matching > sessions shown)

The right session may have been ranked out of the top N. Narrow before expanding:

1. **Narrow scope** — if you haven't already, re-run with `--scope project --cwd <project-path>`. If the user mentioned a project, use it. This is usually enough.
2. **Narrow keywords** — try more specific terms (a filename, a Jira ticket ID, a distinctive phrase the user remembers).
3. **Increase cap as last resort** — if narrowing isn't possible, retry with `--max-results 30`.

Never tell the user the session wasn't found when the cap was applied — you haven't seen all the results yet.

### Step 3c: Zero or few results, cap not applied

The keywords genuinely didn't match. Try variations:
- Split compound/hyphenated terms: `app-deploy` → try `app deploy` or `deploy` alone
- Try synonyms or adjacent terms the session might have used
- Reduce to a single highly distinctive keyword

## Step 4: Detect interactive vs. non-interactive mode

Check the environment before presenting results:

```bash
printenv CLAUDE_CODE_ENTRYPOINT
```

- `cli` → **interactive mode**: can ask follow-up questions
- `sdk-cli` → **non-interactive mode** (`-p`/`--print`): output must be fully self-contained; no follow-up is possible

## Step 5: Summarize and present

For each session write a short (≤10 word) summary label. Always include a `Session ID` column for unnamed sessions — it lets the user pass the ID directly to `/resume` without needing to ask.

```
Found N sessions matching "<keywords>":

#  Date        Project          Name                      Session ID    Summary
1  2026-03-30  backend-service                            a1b2c3d4      Auth token refresh design sync
2  2026-03-12  my-api-project   cache-invalidation-fix                  Deploy pipeline phases design
3  2026-03-25  backend-service                            e5f6g7h8      Rate limiting implementation proposal
```

**Date:** `YYYY-MM-DD` from `last_timestamp`.
**Project:** `basename(project_dir)`.
**Name:** `session_name` if set (manually assigned custom title), blank otherwise. Do not invent or infer names.
**Session ID:** first 8 characters of `session_id` for unnamed sessions, blank for named ones (the name is sufficient).
**Summary:** Use `away_summary` when present — it's a full-arc recap generated by Claude Code and is more reliable than synthesizing from exchanges. Fall back to deriving from `first_exchanges`, `last_exchanges`, and `match_contexts` when `away_summary` is null.

## Step 6: Provide resume command(s)

**Interactive mode (`cli`):**

If there is exactly one candidate and it's an obvious match — its `session_name` directly matches the user's query, or it's the only result with a substantially higher `match_count` than any alternative — give the resume command immediately without prompting:

```bash
cd <project_dir> && claude --resume <session_name_or_id>
```

Otherwise ask the user to pick a number, then show the resume command.

**Non-interactive mode (`sdk-cli`):**

Output is the final response — list resume commands for all candidates, best match first:

```
To resume the best match:
cd <project_dir> && claude --resume <session_name_or_id>

Other candidates:
cd <project_dir2> && claude --resume <session_name_or_id2>
cd <project_dir3> && claude --resume <session_name_or_id3>
```

**Resume argument:** Use `session_name` when the session has one (it's more readable and works with `--resume`); fall back to `session_id` for unnamed sessions.
