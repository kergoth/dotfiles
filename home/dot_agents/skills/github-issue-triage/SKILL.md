---
name: github-issue-triage
description: Run end-to-end GitHub issue triage using the local triage scripts and parallel subagent scoring. Use when asked to create, refresh, update, or rerun issue triage markdown with complexity, difficulty, benefit, scope, and execution-lane recommendations (`agent-implementation`, `agent-assist-human`, `human-only`). Also use when the user says "re-triage", "update the triage doc", "only score new issues", or wants to refresh triage without re-scoring everything.
---

# GitHub Issue Triage

## Overview

Use this skill to run a full triage pass from scratch: fetch issues, chunk work, dispatch parallel subagents for scoring, consolidate results, and regenerate the triage report.

## Inputs

- `repo`: GitHub repo in `owner/name` form (default: current repo)
- `task_dir`: working artifact directory (default: `.agent/tasks/YYYY-MM-DD-issue-triage`)
- `output_doc`: markdown target (default: `docs/github-issue-triage.md`)
- `chunk_count`: number of scoring chunks (default: `5`)

## Pre-step: Check for Local Export

If `github-data/` exists in the current directory, the prepare script uses it
automatically instead of calling the GitHub API. To set this up:

```bash
github-export owner/repo   # sync issue data locally; re-run to refresh
```

## Workflow

Set a script path first (the script resolves symlinks to find sibling bundled scripts):
```bash
triage_script="<skill_dir>/scripts/generate-github-issue-triage"
```

1. Prepare snapshot and chunks.
   ```bash
   "$triage_script" -m prepare -r <repo> -t <task_dir> -c <chunk_count>
   ```

2. Dispatch one subagent per chunk in parallel (`chunk-1.json` to `chunk-N.json`).
   - Each subagent must read one chunk and write one output file:
     - input: `<task_dir>/chunk-N.json`
     - output: `<task_dir>/scored-chunk-N.json`
   - Required output schema per issue:
     - `number` (int)
     - `title` (string)
     - `complexity` (1-5)
     - `difficulty` (1-5)
     - `benefit` (1-5)
     - `scope` (`XS|S|M|L|XL`)
     - `lane` (`agent-implementation|agent-assist-human|human-only`)
     - `confidence` (`low|medium|high`)
     - `rationale` (short text)

3. Wait for all scoring subagents and verify chunk completeness.
   - Confirm `scored-chunk-*.json` count matches `chunk_count`.
   - Fail closed if any chunk is missing.

4. Consolidate and render report.
   ```bash
   "$triage_script" -m consolidate -t <task_dir> -o <output_doc> -c <chunk_count>
   ```

5. Return a short summary with:
   - issue count evaluated
   - lane distribution
   - top candidate list location (`<output_doc>`)
   - artifact directory (`<task_dir>`)

## Scoring Rubric

- `complexity`: implementation breadth and coupling.
- `difficulty`: technical risk and probability of failed first pass.
- `benefit`: user/repo value if completed.
- `scope`: estimated change size (`XS` to `XL`).
- `lane`:
  - `agent-implementation`: bounded and low-risk coding work.
  - `agent-assist-human`: mixed implementation plus human judgment.
  - `human-only`: strategic, security-sensitive, or policy decisions.

## Incremental Update Workflow

Use this when the user wants to **refresh** an existing triage doc rather than re-score everything from scratch. Issues whose `updatedAt` timestamp hasn't changed since the last run are carried forward with their previous scores — only new and modified issues go to subagents. This is much faster for large repos.

`updatedAt` is the right signal: GitHub updates it on any issue edit, label change, or new comment, any of which can affect triage choices.

### When to use vs. full workflow

Use incremental when a previous `scored-all-enriched.json` artifact exists and the user asks to refresh/update. Fall back to the full workflow if no previous run is found.

### Step 1: Locate the previous run

Find the most recent task dir with a completed enriched output:

```bash
prev_enriched=$(ls -d .agent/tasks/*-issue-triage/scored-all-enriched.json 2>/dev/null | sort | tail -1)
```

If nothing is found, use the full workflow instead.

### Step 2: Fetch current snapshot

Run prepare as normal — it always fetches the full current issue list from the API or `github-data/`:

```bash
"$triage_script" -m prepare -r <repo> -t <task_dir>
```

### Step 3: Partition issues by change status

Compare `open-issues.json` against the previous enriched run using `updatedAt`:

```bash
# Identify unchanged issue numbers (same updatedAt as previous run)
jq --slurpfile prev "$prev_enriched" \
  '($prev[0] | map({key: (.number|tostring), value: .updatedAt}) | from_entries) as $prev_ts |
   [.[] | select($prev_ts[(.number|tostring)] == .updatedAt) | .number]' \
  "$task_dir/open-issues.json" > "$task_dir/carry-forward-numbers.json"

# Extract carry-forward scores in scored-chunk format (no enriched fields)
jq --slurpfile nums "$task_dir/carry-forward-numbers.json" \
  '[.[] | select(.number | IN($nums[0][])) |
   {number, title, complexity, difficulty, benefit, scope, lane, confidence, rationale}]' \
  "$prev_enriched" > "$task_dir/scored-chunk-0.json"

# Issues needing re-scoring: new, modified, or absent from previous run
jq --slurpfile nums "$task_dir/carry-forward-numbers.json" \
  '[.[] | select(.number | IN($nums[0][]) | not)]' \
  "$task_dir/open-issues.json" > "$task_dir/rescore-issues.json"
```

Log carry-forward count, rescore count, and how many issues from the previous run are no longer in the current snapshot (removed/closed).

### Step 4: If nothing needs rescoring

If `rescore-issues.json` is empty (`jq 'length' ... == 0`), skip subagent scoring entirely:

```bash
"$triage_script" -m consolidate -t <task_dir> -o <output_doc> -c 1
```

Consolidate reads `scored-chunk-0.json` (carry-forward) and re-enriches from the full `open-issues.json`.

### Step 5: Chunk and score changed issues

Chunk only `rescore-issues.json` — not the full snapshot. Choose K proportional to the rescore set (e.g., `ceil(rescore_count / 20)`, minimum 1):

```bash
rescore_count=$(jq 'length' "$task_dir/rescore-issues.json")
# agent picks K based on rescore_count

i=0
while [ "$i" -lt "$k" ]; do
  jq --argjson m "$i" --argjson n "$k" \
    'to_entries | map(select((.key % $n)==$m) | .value)' \
    "$task_dir/rescore-issues.json" > "$task_dir/chunk-$((i+1)).json"
  i=$((i+1))
done
```

Dispatch subagents for chunks 1..K only (not chunk-0). Each subagent reads its `chunk-N.json` and writes `scored-chunk-N.json` using the standard scoring schema.

### Step 6: Consolidate

Wait for all scoring subagents. Total chunk count for consolidate is K+1 (K scored chunks plus the carry-forward chunk-0):

```bash
"$triage_script" -m consolidate -t <task_dir> -o <output_doc> -c $((k + 1))
```

Consolidate reads all `scored-chunk-*.json` files (including `scored-chunk-0.json`), re-enriches with current `url/updatedAt/createdAt` from `open-issues.json`, and renders the report.

### Step 7: Summary

Report:
- Issues carried forward (unchanged)
- Issues re-scored (new or modified)
- Issues dropped from output (removed from current snapshot, e.g., closed)
- Output location

## Failure Handling

- If issue snapshot fetch fails, report the command and stop.
- If any scoring chunk is missing or malformed JSON, report the missing chunks and stop.
- Do not regenerate markdown from partial scoring data.
