# Obsidian CLI Command Reference

Full reference for the built-in `obsidian` CLI (Obsidian 1.12+).

## Targeting Reference

| Parameter | Resolves by | Use when |
|-----------|-------------|----------|
| `file=<name>` | Note title (wikilink resolution — searches entire vault) | You know the note name but not its location |
| `path=<path>` | Exact vault-relative path (e.g., `Projects/Alpha/spec.md`) | You know the exact location |
| `vault=<name>` | Vault name or ID — **must come first** | Targeting a non-active vault |

## File Management

| Command | Parameters | Notes |
|---------|------------|-------|
| `read` | `file=`, `path=` | Returns file contents |
| `create` | `name=`, `path=`, `content=`, `template=`, `overwrite`, `open`, `newtab` | `template=` requires the core Templates plugin (not Templater); check vault CLAUDE.md |
| `append` | `file=`, `path=`, `content=` (required), `inline` | `inline` appends without leading newline |
| `prepend` | `file=`, `path=`, `content=` (required), `inline` | `inline` prepends without trailing newline |
| `move` | `file=`, `path=`, `to=` (required) | `to=` is destination folder or full path |
| `rename` | `file=`, `path=`, `name=` (required) | `name=` is new filename |
| `delete` | `file=`, `path=`, `permanent` | Without `permanent`, moves to Obsidian trash |
| `file` | `file=`, `path=` | Shows file metadata/info |
| `files` | `folder=`, `ext=`, `total` | Lists vault files; filter by folder or extension |
| `outline` | `file=`, `path=`, `format=tree\|md\|json`, `total` | Returns heading structure |
| `wordcount` | `file=`, `path=`, `words`, `characters` | Word/character count |
| `open` | `file=`, `path=`, `newtab` | Opens file in Obsidian |

## Daily Notes & Tasks

| Command | Parameters | Notes |
|---------|------------|-------|
| `daily` | `paneType=tab\|split\|window` | Opens today's daily note |
| `daily:append` | `content=` (required), `inline`, `open`, `paneType=` | Append to today's daily note |
| `daily:prepend` | `content=` (required), `inline`, `open`, `paneType=` | Prepend to today's daily note |
| `daily:read` | — | Read today's daily note |
| `daily:path` | — | Get daily note file path |
| `tasks` | `file=`, `path=`, `total`, `done`, `todo`, `status="<char>"`, `verbose`, `format=json\|tsv\|csv`, `active`, `daily` | List tasks; filter by status/file |
| `task` | `ref=<path:line>`, `file=`, `path=`, `line=`, `toggle`, `done`, `todo`, `daily`, `status="<char>"` | Get or update a specific task |

## Search & Navigation

| Command | Parameters | Notes |
|---------|------------|-------|
| `search` | `query=` (required), `path=`, `limit=`, `total`, `case`, `format=text\|json` | Full-text search |
| `search:context` | `query=` (required), `path=`, `limit=`, `case`, `format=text\|json` | Search with surrounding line context |
| `backlinks` | `file=`, `path=`, `counts`, `total`, `format=json\|tsv\|csv` | Files that link to the target |
| `links` | `file=`, `path=`, `total` | Outgoing links from a file |
| `orphans` | `total`, `all` | Files with no incoming links |
| `deadends` | `total`, `all` | Files with no outgoing links |
| `unresolved` | `total`, `counts`, `verbose`, `format=json\|tsv\|csv` | Unresolved (broken) links in vault |

## Metadata

| Command | Parameters | Notes |
|---------|------------|-------|
| `tags` | `file=`, `path=`, `total`, `counts`, `sort=count`, `format=json\|tsv\|csv`, `active` | List tags in vault or file |
| `tag` | `name=` (required), `total`, `verbose` | Info on a specific tag |
| `aliases` | `file=`, `path=`, `total`, `verbose`, `active` | List aliases |
| `properties` | `file=`, `path=`, `name=`, `total`, `sort=count`, `counts`, `format=yaml\|json\|tsv`, `active` | List frontmatter properties |
| `property:read` | `name=` (required), `file=`, `path=` | Read a property value |
| `property:set` | `name=` (required), `value=` (required), `type=text\|list\|number\|checkbox\|date\|datetime`, `file=`, `path=` | Set a property |
| `property:remove` | `name=` (required), `file=`, `path=` | Remove a property |
| `bookmarks` | `total`, `verbose`, `format=json\|tsv\|csv` | List bookmarks |
| `bookmark` | `file=`, `subpath=`, `folder=`, `search=`, `url=`, `title=` | Add a bookmark |

## Vault & Navigation

| Command | Parameters | Notes |
|---------|------------|-------|
| `vault` | `info=name\|path\|files\|folders\|size` | Vault info |
| `vaults` | `total`, `verbose` | List known vaults |
| `folders` | `folder=`, `total` | List folders |
| `folder` | `path=` (required), `info=files\|folders\|size` | Folder info |
| `recents` | `total` | Recently opened files |
| `random` | `folder=`, `newtab` | Open a random note |
| `random:read` | `folder=` | Read a random note |
| `tabs` | `ids` | List open tabs |

## Plugins & Commands

| Command | Parameters | Notes |
|---------|------------|-------|
| `command` | `id=` (required) | Execute an Obsidian command by ID |
| `commands` | `filter=` | List available command IDs |
| `hotkey` | `id=` (required), `verbose` | Get hotkey for a command |
| `hotkeys` | `total`, `verbose`, `format=json\|tsv\|csv`, `all` | List hotkeys |
| `plugins` | `filter=core\|community`, `versions`, `format=json\|tsv\|csv` | List plugins |
| `plugins:enabled` | `filter=`, `versions`, `format=` | List enabled plugins |
| `plugin` | `id=` (required) | Plugin info |
| `plugin:reload` | `id=` (required) | Reload plugin (developer use) |
| `plugin:enable` | `id=` (required) | Enable a plugin — requires explicit user request or approval |
| `plugin:disable` | `id=` (required) | Disable a plugin — requires explicit user request or approval |
| `plugin:install` | `id=` (required), `enable` | Install community plugin — requires explicit user request or approval |
| `plugin:uninstall` | `id=` (required) | Uninstall community plugin — requires explicit user request or approval |

## Developer

| Command | Parameters | Notes |
|---------|------------|-------|
| `eval` | `code=` (required) | Execute JavaScript in vault context; use with caution |
| `devtools` | — | Toggle Electron dev tools |
| `dev:screenshot` | `path=` | Take a screenshot |
| `dev:dom` | `selector=` (required), `total`, `text`, `inner`, `all`, `attr=`, `css=` | Query DOM elements |
| `dev:css` | `selector=` (required), `prop=` | Inspect CSS with source locations |
| `dev:console` | `clear`, `limit=`, `level=log\|warn\|error\|info\|debug` | Show captured console messages |
| `dev:errors` | `clear` | Show captured errors |
| `dev:debug` | `on`, `off` | Attach/detach Chrome DevTools Protocol debugger |
| `dev:cdp` | `method=` (required), `params=` | Run a Chrome DevTools Protocol command |
| `dev:mobile` | `on`, `off` | Toggle mobile emulation |

## Output Formats

| Format | Description | Default for |
|--------|-------------|-------------|
| `tsv` | Tab-separated values | Most list commands |
| `json` | JSON array/object | Structured data |
| `csv` | Comma-separated values | Spreadsheet export |
| `yaml` | YAML format | `properties` |
| `tree` | ASCII tree view | `outline` |
| `md` | Markdown | `outline`, `search` |
| `text` | Plain text | `search` |

## Multiline Content

Use `\n` for newlines, `\t` for tabs within quoted strings:

```bash
# Two-line prepend: heading + blank line
obsidian prepend file="Sprint Planning" content="## Goals\n"

# Multi-line task entry
obsidian daily:append content="- [ ] Task 1\n- [ ] Task 2"
```

## Error Conditions

| Error | Cause | Fix |
|-------|-------|-----|
| Connection refused / timeout | Obsidian app not running | Launch Obsidian |
| CLI not enabled | Settings not configured | Settings → General → CLI → Enable |
| File not found | Wrong name/path | Verify with `obsidian files` or exact path |
| Templates plugin not enabled | `template=` used without core Templates plugin | Requires core Templates plugin specifically (Templater alone is insufficient); do not enable without user approval |
| Template not found | Wrong template name | Check Templates folder; name without extension |
| Vault not found | Wrong `vault=` value | Check with `obsidian vaults` |
| Binary not found | PATH not set | Source `~/.zprofile` or add to PATH manually |
