---
name: dispatch-external-model
description: CLI command syntax for running prompts through external model agents (claude, cursor, codex, gemini) as subprocesses. Use for cross-model review, second-opinion queries, or multi-model workflows via CLI dispatch, or when the task specifically requires the external CLI's own harness environment — its tools, hooks, config files, and permission model.
---

# Dispatch to External Model

CLI commands for running prompts through external model agents non-interactively.

## Quick Reference

| Tool | Command |
|------|---------|
| Claude | `claude -p "prompt"` |
| Cursor | `agent -p --trust "prompt"` |
| Codex | `codex exec -s read-only --skip-git-repo-check "prompt"` |
| Gemini | `gemini -p "prompt"` |

These CLIs move fast and drop flags between releases. Confirm a flag with `<tool> --help` before dispatching a long or backgrounded run, and read the output rather than the exit code to decide whether the dispatch worked. At least one of them (Codex) exits 0 after refusing an unknown argument.

## Claude (Anthropic)

```bash
claude -p "prompt"
```

- `-p` — print mode (non-interactive, output to stdout)
- `--model <model>` — specify model (e.g., `sonnet`, `opus`)
- Respects `settings.json` permission allowlists by default
- Works within Claude Code sandbox

**Auto-safe (on request):** Add `--permission-mode acceptEdits` to auto-approve file edits, or `--permission-mode auto` for broader auto-approval within configured limits.

**Full YOLO (on request + user approval):** Add `--dangerously-skip-permissions` to bypass all permission checks. Only use when the user explicitly requests this level of trust.

## Cursor (Claude via Cursor API)

```bash
agent -p --trust "prompt"
```

- `-p` — print mode (non-interactive, output to stdout)
- `--trust` — trust the current workspace (required for headless execution)
- `--model <model>` — specify model (e.g., `sonnet-4`, `gpt-5`)

**Sandbox requirement:** Cursor requires macOS system certificate trust settings. Run with `dangerouslyDisableSandbox: true` in Claude Code.

**Auto-approve (on request):** Add `--yolo` or `--force` to auto-approve all tool calls. Requires user approval before invoking.

## Codex (OpenAI)

```bash
codex exec -s read-only --skip-git-repo-check "prompt"
```

- Bare `codex exec "prompt"` prompts for approvals and may hang or fail non-interactively
- `-s`, `--sandbox <mode>` — `read-only`, `workspace-write`, or `danger-full-access`. Use `read-only` for review and analysis
- `--skip-git-repo-check` — safe to always include; required when the working directory is not a Git repo (without it Codex refuses to start)
- `-m <model>` — specify model
- `-o <file>` — write last message to file
- `--json` — print events as JSONL. Use this when you need to see progress; otherwise Codex buffers everything and writes at exit, so a running dispatch shows an empty output file the whole time
- `--ephemeral` — run without persisting session files to disk

**There is no `--full-auto` flag.** Earlier versions had one, and this skill documented it until 2026-09-10. Current versions reject it outright. Use `-s workspace-write` for the equivalent sandboxed-write behavior.

**Verify the flags before trusting the result.** Codex exits 0 when it rejects an unknown argument, so a dispatch that ran nothing reports success. A wrapper that keys off the exit code (including Claude Code's background-task notification) will claim the task completed. Read the actual output before reporting a Codex review, and treat a short output that starts with `error: unexpected argument` as a failed dispatch, not a finding.

```text
$ codex exec --full-auto "review this"
error: unexpected argument '--full-auto'
```
Exit code: 0. Treat as failure, not an empty review.

**Sandbox requirement:** Codex requires write access to `~/.codex/sessions`. Run with `dangerouslyDisableSandbox: true` in Claude Code.

**Auto-safe (on request):** Add `-s workspace-write` for automatic execution inside a sandbox that permits writes to the working directory. Add `--approve-for-me` to auto-approve tool calls via Codex's built-in review (no interactive prompt).

**Full YOLO (on request + user approval):** Add `--dangerously-bypass-approvals-and-sandbox` to skip all prompts and sandboxing. Only use when the user explicitly requests this level of trust.

## Gemini (Google)

```bash
gemini -p "prompt"
```

- `-p` / `--prompt` — non-interactive mode
- `-o json` — output as JSON
- `-o stream-json` — output as JSONL

**Sandbox status:** Unknown — not yet tested. May require `dangerouslyDisableSandbox: true`.

**Auto-safe (on request):** Add `--approval-mode auto_edit` to auto-approve file edits only.

**Full YOLO (on request + user approval):** Add `--approval-mode yolo` to auto-approve all actions. Only use when the user explicitly requests this level of trust.

## Sandbox Escaping

When dispatching from within a sandboxed agent (e.g., Claude Code), the sandbox applies to child processes. This means **all external model CLIs require sandbox escalation**, even Claude calling Claude.

**From Claude Code:** Use `dangerouslyDisableSandbox: true` in the Bash tool for all external model dispatch. The child process inherits sandbox restrictions that block session/state directory writes.

**From Cursor:** Cursor has no per-tool-call sandbox escape (unlike Claude's `dangerouslyDisableSandbox`). Options:
- **Interactive mode**: User approves each command when prompted
- **Allowlist**: Pre-configure commands in `permissions.json` (`terminalAllowlist`)
- **Full YOLO**: Use `--yolo` flag — requires explicit user request and approval

**From Codex:** `-s workspace-write` confines Codex to the working directory. External CLIs that need to write outside the workspace will fail.

## Trust Levels

When dispatching to external models, use the minimum trust level needed:

1. **Default** — Use the base commands above. For Codex, default means `-s read-only` (non-interactive-safe). Bare `codex exec` or other tools without sandbox flags may still prompt for approvals and fail non-interactively.

2. **Auto-safe** — Use `--permission-mode acceptEdits` (Claude), `-s workspace-write` (Codex), or `--approval-mode auto_edit` (Gemini) when the calling agent explicitly requests autonomous execution. These maintain sandboxing or limit auto-approval to edits.

3. **Full YOLO** — Use `--dangerously-skip-permissions` (Claude), `--dangerously-bypass-approvals-and-sandbox` (Codex), `--approval-mode yolo` (Gemini), or `--yolo` (Cursor) only when:
   - The calling agent explicitly requests full autonomous execution
   - You have confirmed with the user that this level of trust is acceptable
