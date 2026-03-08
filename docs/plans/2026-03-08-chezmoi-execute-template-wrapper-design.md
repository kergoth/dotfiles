# Chezmoi Execute-Template Wrapper Design

**Date:** 2026-03-08
**Status:** Approved

## Problem

Validation commands in docs and guidance should use:

```
scripts/chezmoi-execute-template path/to/template.tmpl
```

In agent workflows, redirection prompts add friction and slow down routine checks.
`chezmoi cat --source-path` can render managed sources, but does not cover
unmanaged templates (e.g., `scripts/setup-system-*.tmpl`).

## Design

### Wrapper Script

Add a concise wrapper at `scripts/chezmoi-execute-template`:

- Accepts one or more file paths.
- For each file, runs `cat "$file" | chezmoi execute-template` separately.
- No additional argument handling, prompts, or output framing.

### Guidance

Update `CLAUDE.md` examples to use the wrapper for template rendering. Mention
`chezmoi cat --source-path` as an optional alternative for managed files.

## Data Flow

Input files are read one at a time and piped to `chezmoi execute-template`.
Output is the raw rendered template to stdout, in argument order.

## Error Handling

- Missing/unreadable files: `cat` error propagates; wrapper exits non-zero.
- Template rendering failure: `chezmoi execute-template` error propagates.
- No custom error messages.

## Files to Modify

| File | Change |
|------|--------|
| `scripts/chezmoi-execute-template` | New wrapper script |
| `CLAUDE.md` | Use wrapper in examples; optional `chezmoi cat --source-path` note |

## Verification

- `scripts/chezmoi-execute-template home/.chezmoiscripts/linux/run_onchange_after_10_install-apps.tmpl`
