---
name: github-issue-triage
description: Run end-to-end GitHub issue triage using the local triage scripts and parallel subagent scoring. Use when asked to create, refresh, or rerun issue triage markdown with complexity, difficulty, benefit, scope, and execution-lane recommendations (`agent-implementation`, `agent-assist-human`, `human-only`).
---

# GitHub Issue Triage

## Overview

Use this skill to run a full triage pass from scratch: fetch issues, chunk work, dispatch parallel subagents for scoring, consolidate results, and regenerate the triage report.

## Inputs

- `repo`: GitHub repo in `owner/name` form (default: current repo)
- `task_dir`: working artifact directory (default: `.agent/tasks/YYYY-MM-DD-issue-triage`)
- `output_doc`: markdown target (default: `docs/github-issue-triage.md`)
- `chunk_count`: number of scoring chunks (default: `5`)

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

## Failure Handling

- If issue snapshot fetch fails, report the command and stop.
- If any scoring chunk is missing or malformed JSON, report the missing chunks and stop.
- Do not regenerate markdown from partial scoring data.
