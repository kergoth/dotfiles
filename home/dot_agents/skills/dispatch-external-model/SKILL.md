---
name: dispatch-external-model
description: CLI syntax for dispatching prompts to external model agents (claude, cursor, codex, gemini). Use when spawning a second-opinion review, running prompts through alternate models, or scripting multi-model workflows.
---

# Dispatch to External Model

CLI commands for running prompts through external model agents non-interactively.

## Quick Reference

| Tool | Command |
|------|---------|
| Claude | `claude -p "prompt"` |
| Cursor | `agent -p --trust "prompt"` |
| Codex | `codex exec "prompt"` |
| Gemini | `gemini -p "prompt"` |

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
codex exec "prompt"
```

- Default mode prompts for approvals (may fail non-interactively)
- `-m <model>` — specify model
- `-o <file>` — write last message to file
- `--json` — output as JSONL

**Sandbox requirement:** Codex requires write access to `~/.codex/sessions`. Run with `dangerouslyDisableSandbox: true` in Claude Code.

**Auto-safe (on request):** Add `--full-auto` for sandboxed automatic execution (auto-approves within workspace-write sandbox).

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

**From Codex:** Codex's `--full-auto` runs in a workspace-write sandbox. External CLIs that need to write outside the workspace will fail.

## Trust Levels

When dispatching to external models, use the minimum trust level needed:

1. **Default** — Use the base commands above. The external agent may prompt for approvals (which fails non-interactively for read-only tasks, but is safest).

2. **Auto-safe** — Use `--permission-mode acceptEdits` (Claude), `--full-auto` (Codex), or `--approval-mode auto_edit` (Gemini) when the calling agent explicitly requests autonomous execution. These maintain sandboxing or limit auto-approval to edits.

3. **Full YOLO** — Use `--dangerously-skip-permissions` (Claude), `--dangerously-bypass-approvals-and-sandbox` (Codex), `--approval-mode yolo` (Gemini), or `--yolo` (Cursor) only when:
   - The calling agent explicitly requests full autonomous execution
   - You have confirmed with the user that this level of trust is acceptable
