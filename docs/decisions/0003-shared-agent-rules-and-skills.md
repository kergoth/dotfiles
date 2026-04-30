---
status: accepted
date: 2026-03-13
decision-makers: kergoth
---

# Shared Agent Rules and Skills via ~/.agents/

## Context and Problem Statement

Claude and Codex are both active development tools but had uneven configuration. Claude relied on plugins (`superpowers`, `learning-output-style`, `claude-md-management`) as the source of truth for shared skills and persistent instructions. Codex had no equivalent skill layer. This meant portable behavior — skills, coding conventions, output style — was Claude-specific and could not be shared with other agents without duplicating content. Plugins also deliver content implicitly during agent startup, making the provenance and update path opaque.

## Decision Drivers

* Skills and instructions that are agent-neutral should not live in a Claude-only delivery path
* Third-party skill content should be pinned and reviewable, not fetched live at startup
* Adding a new agent should not require duplicating the skill and rule setup
* Updates to shared content should be explicit and visible, not implicit

## Considered Options

* Continue relying on Claude plugins for shared workflows
* Use an external skill manager (e.g., `npx skills`, `skillshare`) as a global baseline
* Build a custom skill installer with a dedicated lockfile
* Shared repo-managed layer (`~/.agents/`) with thin agent-specific overlays

## Decision Outcome

Chosen option: "Shared repo-managed layer (`~/.agents/`)", because it provides a single source of truth for portable content, integrates with the existing chezmoi externals pinning model, and avoids adding an external dependency or building a new package management system.

### Consequences

* Good, because Claude and Codex share one skill baseline managed from this repo
* Good, because third-party skills are fetched as pinned externals and linked in, using the existing review-before-adopt workflow
* Good, because adding a new agent requires only a thin overlay pointing at the shared skill tree
* Good, because portable behavior is in dotfiles, not locked inside a plugin's release process
* Bad, because Claude-specific native integrations (MCP, LSP hooks) still require agent-specific config and cannot be shared
* Neutral, because the `astral` plugin is retained temporarily for potential `ty` LSP integration until a declarative path is verified

### Confirmation

After `chezmoi apply`:
- `~/.agents/skills/` contains the shared skill set
- `~/.claude/` and `~/.codex/` each symlink or render from the shared layer
- `chezmoi apply` does not update pinned external SHAs (updates are explicit via `script/update`)

## More Information

Repository responsibility split:
- `home/dot_agents/` — shared skills, symlinks to approved third-party content, rendered shared rules under `rules/`
- `settings/agents/` — backing fragments for shared rules, including sensitive or profile-specific content
- `home/dot_claude/` — Claude-specific config, MCP wiring, retained native integrations
- `home/dot_codex/` — Codex-specific config

Alternatives rejected:
- Claude plugins: makes Claude the source of truth for behavior that should be portable
- External skill managers: adds dependency and state complexity without solving pinning or provenance
- Custom installer: would become a lightweight package manager, broader than the problem
