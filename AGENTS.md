# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Repository Safety and Source Discipline

Edit chezmoi source, never rendered files in `$HOME`; chezmoi overwrites rendered targets on apply.

Before editing any home-directory target, run:

```bash
chezmoi source-path <target>
```

Edit returned repository path. Do not infer source path from target name.

Use `chezmoi cat --source-path <source>`, `scripts/chezmoi-execute-template`, and `chezmoi diff` to render and inspect changes. Run `chezmoi apply` only when applying to the live home directory is part of the requested task.

State-changing commands (`chezmoi apply`, `./script/setup`, `./script/setup-system`, `./script/home-manager-switch`, `./script/update`, direct chezmoi updates, external refresh) require explicit user authorization. Agents may mention these when relevant, but should not run them unless explicitly asked.

This repository is public. When a commit changes an `.age` file, keep the subject and body vague — describe the shape of the change without naming plaintext specifics (people, companies, tools, internal URLs) the encryption is meant to protect.

## Reference Guides

| Guide | When to consult |
|-------|-----------------|
| `docs/repository-architecture.md` | Understanding directory layout, setup progression, or source-to-rendered flow |
| `docs/chezmoi-authoring.md` | Editing templates, variables, run scripts, secrets, or troubleshooting |
| `docs/testing.md` | Choosing the right verification method for a change |
| `docs/contributing-software.md` | Adding, removing, or configuring software packages |
| `docs/inventory.md` | Finding installed software, included external projects, plugins, fonts, scripts, and system or desktop components |
| `docs/customization.md` | Understanding local override paths and machine-specific customization escape hatches |
| `docs/agent-configuration.md` | Managing agent rules, skills, or subagent configs |
| `docs/updating-externals.md` | Reviewing and applying external dependency updates |
| `docs/commenting-standard.md` | Full commenting rules, examples, and rationale |
| `docs/decisions/` | Understanding past architectural decisions (list via `ls docs/decisions/`) |

## Verification

Pick the cheapest verification that covers the changed behavior. Prefer render checks and targeted tests before container-wide runs. For platform-dependent behavior, run the smallest safe behavioral check in the affected runtime; source inspection alone is insufficient. See `docs/testing.md` for the full verification matrix.

Common read-only commands: `chezmoi diff`, `chezmoi cat --source-path`, `scripts/chezmoi-execute-template`, `./script/test -n`.

## Commit and Development Workflow

Personal repository; no pull request workflow. Prefix commit subjects by subsystem (e.g., `agents:`, `zsh:`, `chezmoi:`), not by containing directory. Scope direct-main/no-PR behavior to agents operating in the owner's repository so it does not contradict external CONTRIBUTING instructions.

- Branch from `main` for features; use worktrees when working in parallel.
- Merge to `main` when complete. Never open PRs or suggest PR-based review flows.
- Reference GitHub Issues in commit bodies when a commit closes or advances one.

## Commenting Conventions

See `docs/commenting-standard.md` for full detail and examples. Rules apply to
new and modified code only — do not backfill.

**Foundation (Ottinger's Rules):**
- Comments are for things that cannot be expressed in code.
- Comments that restate code must be deleted.
- If a comment says what the code could say, change the code instead.

**Required:**
- Workarounds must reference the upstream issue (URL or bug tracker link).
- Non-obvious chezmoi template conditions need a WHY comment; simple OS/platform guards do not.
- `run_once_` and `run_onchange_` scripts need a one-line comment at the top stating what triggers them and what they achieve.
- Cross-file sync dependencies must be called out explicitly.

**Prohibited:**
- Comments that restate what the code does must be removed from new and modified code.
- When removing code, remove its comments too. Do not leave orphaned explanations for things that no longer exist.

## Script Conventions

Read and apply the `shell-script-style` skill before substantial edits. Source `scripts/common.sh` (or `scripts/common.ps1` for PowerShell) instead of reimplementing shared helpers. See `docs/chezmoi-authoring.md#shared-template-and-script-helpers` for helper semantics.

## Architectural Decisions

Significant architectural decisions belong in `docs/decisions/` as MADR-format ADRs. Agents should suggest creating ADRs when a decision is non-obvious, shapes how future work, has meaningful alternatives, and would be valuable to understand without reading full git history. Name new ADRs `NNNN-kebab-case-title.md` with the next available number. See `docs/repository-architecture.md` for ADR location and existing decisions.
