---
name: obsidian-cli
description: Use when running the `obsidian` CLI command, interacting with an Obsidian vault from the terminal, creating/appending/reading notes programmatically, searching vault content, managing daily notes, querying tags or backlinks, or automating any Obsidian vault operations. Requires Obsidian 1.12+, app running, CLI enabled in Settings → General → CLI.
---

# Obsidian CLI

**Built-in CLI in Obsidian 1.12+** — the binary is named `obsidian`, not `obsidian-cli`. Do NOT use third-party tools or shell file manipulation; use this CLI directly.

## Quick Setup

- macOS: modifies `~/.zprofile`; binary inside `/Applications/Obsidian.app/Contents/MacOS`
- Linux: symlink at `/usr/local/bin/obsidian`
- Enable: Settings → General → CLI

Run `obsidian` (no args) for interactive TUI with autocomplete.

## Parameter Syntax — CRITICAL

```
obsidian <command> [parameter=value] [--flag]
```

- **Parameters: bare `parameter=value` — NO dashes, NO `--`**
- Flags: `--flag` (boolean, dashes only for these)
- Vault targeting: `vault=<name>` — must come first
- File targeting: `file=<name>` (wikilink resolution) or `path=<exact/relative/path>`
- Multiline text: use `\n` and `\t` within quoted strings
- Output format: `format=json|tsv|csv|yaml|tree|md`
- Copy to clipboard: `--copy`

## Common Patterns

```bash
# Append task to today's daily note
obsidian daily:append content="- [ ] Review PR"

# Search vault, copy results to clipboard
obsidian search query="project alpha" --copy

# Read note by name (wikilink resolution)
obsidian read file="Meeting Notes 2026-02-15"

# Read note by exact vault-relative path
obsidian read path="Projects/Alpha/spec.md"

# Create note from template
obsidian create name="Sprint Planning" template=Weekly

# Prepend multiline header (use \n for newlines)
obsidian prepend file="Sprint Planning" content="## Goals\n"
```

## Common Mistakes

| Wrong | Right | Why |
|-------|-------|-----|
| `obsidian-cli ...` | `obsidian ...` | It's a built-in binary, not third-party |
| `--file="Note"` | `file="Note"` | Parameters have NO dashes |
| `--path="..."` | `path="..."` | Parameters have NO dashes |
| `daily append` | `daily:append` | Subcommand uses colon separator |
| `grep -r "..." vault/` | `obsidian search query="..."` | Use CLI search; don't fall back to grep |
| `echo "..." >> file` | `obsidian append content="..."` | Use CLI; don't manipulate files directly |
| `... \| pbcopy` | `... --copy` | Use built-in clipboard flag |

## Command Categories

See [commands.md](commands.md) for full reference.

| Category | Commands |
|---|---|
| File Management | `create`, `read`, `append`, `prepend`, `move`, `rename`, `delete` |
| Daily Notes & Tasks | `daily`, `daily:append`, `daily:prepend`, `daily:read`, `daily:path`, `tasks`, `task` |
| Search & Navigation | `search`, `search:context`, `backlinks`, `links`, `orphans`, `deadends`, `unresolved` |
| Metadata | `tags`, `aliases`, `properties`, `property:read`, `property:set`, `bookmarks` |
| Vault Info | `vault`, `vaults`, `files`, `folders`, `file`, `outline`, `wordcount` |
| Developer | `devtools`, `dev:screenshot`, `eval`, `dev:dom`, `dev:css`, `plugin:reload`, `command` |
