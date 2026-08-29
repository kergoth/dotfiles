# Agent Configuration

Agent tools share rule and skill sources where their formats permit it. The
repository renders each tool's required destination rather than treating a
rendered file under `$HOME` as editable configuration.

## Shared Rules

Rule topics live in `home/dot_agents/rules/`. The
`home/.chezmoitemplates/render-agent-rules.md.tmpl` template sorts those files
alphabetically, removes a per-topic H1 heading, and renders the nonempty topics
as one document. It passes an `agent` value so a topic can include content only
for a specific tool.

Current topic ownership is:

| Source | Responsibility |
| --- | --- |
| `10-personal.md.tmpl` | Identity, interaction preferences, personal tooling, and planning |
| `14-conventions.md.tmpl` | Documentation lookup, source lookup, shell, security, Git, and writing conventions |
| `15-implementation-discipline.md.tmpl` | Removal discipline, design conformance, and review quality |
| `20-work.md.tmpl` | Work-only encrypted rules when `.work` and `.secrets` are enabled |
| `30-skill-workflows.md.tmpl` | Skill use, agent tooling design, and CLI discovery |

Add a rule to the owning topic. Do not repeat the same instruction in several
files. Use a condition such as `{{ eq $agent "claude" }}` only when the
instruction depends on a tool's behavior.

## Skills and Agents

Shared skills are rendered or linked under `~/.agents/skills/`:

- First-party maintained skills have source directories under
  `home/dot_agents/skills/`.
- Files named `symlink_<skill>` point at skills supplied by reviewed external
  sources.
- Work-only skills and agents come from encrypted external content and are
  linked by
  `home/.chezmoiscripts/posix/run_onchange_after_40_link-work-agent-content.tmpl`.
- Agent tools link to the shared directory where they support filesystem skill
  discovery. Pi instead names `~/.agents/skills` in its settings.

The source directory is the reliable inventory. A copied catalog in README or
another guide will drift whenever a skill is added, removed, or moved between
first-party and external sources.

Reusable subagents live under `~/.agents/agents/`. Claude Code exposes them
through `~/.claude/agents`; other tools do not currently consume that shared
agent directory.

## Rendered Destinations

| Tool | Source template | Rendered destination |
| --- | --- | --- |
| Shared/default | `home/dot_agents/AGENTS.md.tmpl` | `~/.agents/AGENTS.md` |
| Claude Code | `home/dot_claude/CLAUDE.md.tmpl` | `~/.claude/CLAUDE.md` |
| Codex | `home/dot_codex/AGENTS.md.tmpl` | `~/.codex/AGENTS.md` |
| Cursor | `home/dot_cursor/rules/agent-rules.mdc.tmpl` | `~/.cursor/rules/agent-rules.mdc` |
| Pi | `home/dot_pi/agent/AGENTS.md.tmpl` | `~/.pi/agent/AGENTS.md` |

Edit the source templates and topics. Direct changes to rendered destinations
will be overwritten.

## Agent-Specific Conditionals

The renderer supplies one of `default`, `claude`, `codex`, `cursor`, or `pi`
as the `agent` parameter. Keep shared guidance unconditional. Add a branch
only for a genuine tool capability or workflow difference, and keep the branch
in the topic that owns the rule.

Machine-role conditions remain available because the renderer receives the
root chezmoi context. Work-only content can therefore require both `.work` and
`.secrets`; personal API-backed configuration can require `.personal` and
`.secrets`.

## MCP Server Configuration

There is no cross-agent MCP configuration format. Each tool uses its supported
registration mechanism:

| Tool | Configuration mechanism |
| --- | --- |
| Claude Code | Idempotent `claude mcp add` or `add-json` calls in `run_onchange_after_50_configure-agents.sh.tmpl`, writing `~/.claude.json` |
| Codex | Idempotent `codex mcp add` calls in the same run script, writing `~/.codex/config.toml` |
| Cursor | `home/dot_cursor/private_mcp.json.tmpl` rendered to `~/.cursor/mcp.json` |
| Pi | `home/dot_pi/agent/mcp.json.tmpl` rendered to `~/.pi/agent/mcp.json` for `pi-mcp-adapter` |

Adding one server to several tools requires editing each applicable mechanism.
The run script handles CLI-owned configuration because chezmoi cannot safely
replace the rest of those files. Cursor and Pi accept declarative JSON and can
be rendered directly.

Current source configures Context7, DeepWiki, DuckDuckGo, and Playwright where
the applicable agent and machine conditions allow them. Firecrawl and Kagi
require personal secret-backed API keys. Work templates may add encrypted
servers. Cursor also configures Readwise on persistent personal machines. Read
the templates before changing this list; their conditions are authoritative.

## Verification

Render every affected destination without applying it:

```console
scripts/chezmoi-execute-template home/dot_agents/AGENTS.md.tmpl
scripts/chezmoi-execute-template home/dot_claude/CLAUDE.md.tmpl
scripts/chezmoi-execute-template home/dot_codex/AGENTS.md.tmpl
scripts/chezmoi-execute-template home/dot_cursor/rules/agent-rules.mdc.tmpl
scripts/chezmoi-execute-template home/dot_pi/agent/AGENTS.md.tmpl
```

When an MCP template changes, render that tool's source template as well. Use
`chezmoi diff` to inspect final managed destinations, but apply only when a
live configuration change is intended.

## Troubleshooting

If a rendered rule is missing, inspect
`render-agent-rules.md.tmpl`, confirm the topic filename is included by the
glob, and check whether its agent or machine condition removes all content.

If a skill is missing, inspect the source entry under
`home/dot_agents/skills/`. A `symlink_` file contains the target that chezmoi
will create; it is not itself a filesystem symlink in the source tree.

For MCP problems, identify whether the destination is CLI-owned or
chezmoi-rendered before editing. Changing `~/.claude.json` or
`~/.codex/config.toml` directly bypasses the idempotent setup source and may be
lost or conflict on another machine.

## Related Decisions

- [ADR 0003: Shared Agent Rules and Skills](decisions/0003-shared-agent-rules-and-skills.md)
- [Authoring Chezmoi Configuration](chezmoi-authoring.md)
