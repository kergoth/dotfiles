## Git Conventions
- Follow the [seven rules of commit messages](https://cbea.ms/git-commit):
  - Imperative mood in subject ("Add feature" not "Added feature")
  - Limit subject to 50 characters (72 hard limit), no trailing period
  - Separate subject from body with blank line; wrap body at 72 characters
  - Explain WHY in the body, not WHAT (the diff shows what changed)
- Always use explicit `git add` with specific file paths - never `git add -A`, `git add .`, or `git add -u` without listing files
- Verify edits actually succeeded before committing; check `git diff` if uncertain

## Markdown Conventions
- In documentation files (READMEs, docs/, Obsidian notes): always use proper markdown links - `[descriptive text](url)` or reference-style `[text][ref]` with definitions at the bottom
- Never use bare autolinks (`<http://...>`) or plain unlinked URLs in these contexts - these are the antipattern to avoid
- Plan files, design documents, and conversational responses may use autolinks or bare URLs
- Use descriptive link text that explains the destination; avoid generic text like `[here]`, `[this]`, or `[link]`

## GitHub CLI Conventions
- Prefer explicit `gh` subcommands (`gh pr view`, `gh issue list`) and installed extensions (`gh pr-review`) over raw `gh api` or `gh api graphql` calls
- Fall back to `gh api` only when no subcommand or extension covers the needed operation
- Reason: subcommands are easier to permission-gate, less brittle, and handle pagination/error cases automatically

## Shell Conventions
- **JSON in shell pipelines: use `jq`, not inline Python.** Inline `python3 -c` for JSON is brittle and error-prone due to shell quoting. Do not offer Python as an alternative or "fallback if jq is unavailable" — `jq` is a standard tool; assume it is present. Only use Python when the transformation genuinely exceeds `jq`'s capabilities (complex stateful logic, multi-source joins, etc.).

## Issue Tracking Conventions
- Epics / initiatives: outcome-level — why it exists, what done looks like, what's excluded; no implementation details
- Tasks / stories / enhancements: definition of done, not how to implement
- Bugs: reproduction steps, expected vs actual behavior
- Descriptions must be self-contained — don't reference local files, unlinked docs, or context the reader won't have
