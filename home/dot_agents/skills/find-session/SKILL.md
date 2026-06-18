---
name: find-session
description: >
  Find and resume a past Claude Code, Codex, or Cursor Agent conversation by
  searching session history files by keyword. Use this skill whenever the user
  wants to find a previous conversation, can't remember which directory or agent
  they were using, wants to look up work from a past session, needs to resume a
  session they can't locate with /resume, codex resume, or agent --resume, or
  says something like "I know we discussed X somewhere" or "where was that
  session about Y". Infers search scope, agent, and keywords from the user's
  description and presents matching sessions with summaries before asking which
  to resume. Always use this skill rather than manually searching ~/.claude/,
  ~/.codex/, or ~/.cursor/ yourself.
---

# Find Session

Search past Claude Code, Codex, or Cursor Agent session history by keyword and present matching sessions for resumption.

## Step 1: Infer scope and extract keywords

From the user's description:

**Scope:**
- "in this project" / "here" / "in this repo" / "in this directory" → `--scope project --cwd "$(pwd)"`
- User names a specific project or repo (e.g. "it was in my-api-project", "in the backend-service repo") → resolve the path (check `~/Workspace/`, `~/Repos/`) and use `--scope project --cwd <resolved-path>`
- "somewhere" / "I can't remember" / "I was working on X" / no location specified → `--scope global`
- When ambiguous, default to `--scope global`

**Agent:**
- User says "Claude", "Claude Code", or asks for a Claude session -> `--agent claude`
- User says "Codex" or asks for a Codex session -> `--agent codex`
- User says "Cursor" or asks for a Cursor Agent session -> `--agent cursor`
- User does not identify the agent -> `--agent all`

**Keywords:** Extract 2–4 specific, concrete terms. Prefer domain nouns over generic verbs.
- "that session about the marketplace proposal" → `marketplace proposal`
- "where we set up the mender deployment" → `mender deploy`

## Step 2: Run the search script

```bash
python ~/.agents/skills/find-session/scripts/search_sessions.py \
  --agent <claude|codex|cursor|all> \
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
      "agent":           "claude" | "codex" | "cursor",
      "session_id":      string,           // UUID
      "session_name":    string | null,    // explicit /rename title if set; falls back to first prompt from history.jsonl (may be a slash-command when no other entries exist); null if neither available
      "has_custom_name": boolean,          // true only when session_name came from an explicit /rename; false for fallback names
      "resume_command":  string,           // agent-specific resume command
      "away_summary":    string | null,    // recap summary stored by Claude Code on session pause; null if none
      "project_dir":     string,           // absolute path to project cwd; Cursor may be "" when workspaceStorage is unmapped
      "first_timestamp": string,           // ISO8601
      "last_timestamp":  string,           // ISO8601
      "match_count":     number,           // keyword hit count (relevance signal)
      "match_source":    "parent" | "subagent",  // optional; Cursor only — where the keyword hit occurred
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
python ~/.agents/skills/find-session/scripts/search_sessions.py \
  --agent <claude|codex|cursor|all> \
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
python ~/.agents/skills/find-session/scripts/search_sessions.py \
  --agent <claude|codex|cursor|all> \
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

Use the current agent interface first:

- If you can ask the user a follow-up, use **interactive mode**.
- If this is a one-shot print/API run where no follow-up is possible, use **non-interactive mode**.

For Claude Code, the entrypoint can confirm this:

```bash
printenv CLAUDE_CODE_ENTRYPOINT
```

- `cli` -> **interactive mode**
- `sdk-cli` -> **non-interactive mode** (`-p`/`--print`)
- unset or unknown -> infer from whether this agent run can ask follow-up questions; in Codex, default to **interactive mode** unless the invocation is clearly one-shot

## Step 5: Summarize and present

For each session write a short (≤10 word) summary label. Always include a `Session ID` column for unnamed sessions so the resume command can target the exact session without another lookup.

When `match_source` is `"subagent"`, mention that the keyword match came from subagent work in that session; resume still uses the parent `session_id`.

```
Found N sessions matching "<keywords>":

#  Agent   Date        Project          Name                      Session ID    Summary
1  codex   2026-06-15  dotfiles                                  019ecea4      Find-session Codex support design
2  claude  2026-03-30  backend-service                           a1b2c3d4      Auth token refresh design sync
3  cursor  2026-06-10  dotfiles                                  f7e8d9c0      Cursor workspace path mapping (subagent match)
```

**Agent:** `agent`.
**Date:** `YYYY-MM-DD` from `last_timestamp`.
**Project:** `basename(project_dir)`.
**Name:** `session_name` when `has_custom_name` is true (set via `/rename`), blank otherwise. Do not invent or infer names.
**Session ID:** first 8 characters of `session_id` when `has_custom_name` is false, blank for explicitly named sessions.
**Summary:** Use `away_summary` when present — it's a full-arc recap generated by Claude Code and is more reliable than synthesizing from exchanges. Fall back to deriving from `first_exchanges`, `last_exchanges`, and `match_contexts` when `away_summary` is null.

## Step 6: Provide resume command(s)

Use `resume_command` from the search output when available.

Claude example:

```bash
cd <project_dir> && claude --resume <session_id>
```

Codex example:

```bash
cd <project_dir> && codex resume <session_id>
```

Cursor example:

```bash
cd <project_dir> && agent --resume <session_id>
```

**Cursor resume warning:** `agent --resume` with an invalid UUID silently starts a fresh session instead of erroring. Always use the full parent UUID from search output.

**Cursor platform note:** `project_dir` resolution reads Cursor `workspaceStorage/*/workspace.json` from macOS (`~/Library/Application Support/Cursor/User/workspaceStorage`) and Linux (`~/.config/Cursor/User/workspaceStorage`). Unmapped workspaces or hosts without Cursor installed leave `project_dir` empty; resume falls back to `cd .`.

**Cursor project scope:** When the expected slug directory is missing, search falls back to a global scan but still filters by `--cwd`: prefer the `workspaceStorage` mapping for that path, otherwise compare realpaths (symlinks resolve). Unrelated `--cwd` values return no results; use `--scope global` to search all projects.

**Interactive mode (`cli`):**

If there is exactly one candidate and it's an obvious match — its `session_name` directly matches the user's query, or it's the only result with a substantially higher `match_count` than any alternative — give the resume command immediately without prompting:

```bash
<resume_command>
```

Otherwise ask the user to pick a number, then show the resume command.

**Non-interactive mode (`sdk-cli`):**

Output is the final response — list resume commands for all candidates, best match first:

```
To resume the best match:
<resume_command>

Other candidates:
<resume_command2>
<resume_command3>
```

**Resume argument:** Use `session_name` only when `has_custom_name` is `true` (set via `/rename`). Otherwise always use `session_id` (the full UUID). Session names derived from the first prompt do not work with `--resume`.
