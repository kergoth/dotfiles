# Commenting Standard

This document defines when and how to write comments across all file types in
this repository: shell scripts, zsh snippets, chezmoi templates, config files,
and PowerShell scripts.

This standard applies to **new and modified code only**. Do not backfill
comments on existing files that are not otherwise being changed.

## Foundation: Ottinger's Rules for Comments

Built on [Ottinger's Rules for Comments](https://ruthlesslyhelpful.net/2012/02/25/rules-for-commenting-code/),
three principles:

1. **Comments are for things that cannot be expressed in code.**
2. **Comments which restate code must be deleted.**
3. **If the comment says what the code could say, change the code to make the
   comment redundant.**

## What must be commented (requirements)

### 1. Workarounds must reference the upstream issue

When code works around an upstream bug, limitation, or quirk, include a link or
reference so the workaround can be found and removed when the root cause is
resolved.

```bash
# zsh compinit requires FPATH set before first call; Homebrew's shellenv sets it
# too late when sourced inside .zshrc. https://github.com/Homebrew/brew/issues/XXXX
export FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
```

### 2. Non-obvious chezmoi template conditions need a WHY

Simple OS or platform guards are self-documenting. Complex conditions —
especially those encoding policy decisions or workarounds — need a comment.

```
{{- /* Self-documenting — no comment needed */ -}}
{{ if eq .chezmoi.os "darwin" }}

{{- /* Not self-documenting — comment required */ -}}
{{- /* Nix manages zsh on Linux hosts; chezmoi-managed plugins only on macOS */ -}}
{{ if and (eq .chezmoi.os "darwin") (not (has "nix" .tools)) }}
```

### 3. `run_once_` and `run_onchange_` scripts must state their trigger intent

The filename encodes *when* a script runs but not *why*. A one-line comment at
the top of each such script explains what triggers it and what it achieves.

```bash
# Runs once per machine. Installs Homebrew if absent.
```

```bash
# Re-runs when the Brewfile changes. Installs, upgrades, and removes packages.
```

### 4. Cross-file sync dependencies must be called out

When a file must stay in sync with another — a script that parses config a
template generates, a list maintained in two places — say so explicitly.

```bash
# Keep in sync with home/dot_config/foo/config.tmpl — reads the same key names.
```

## What not to comment

This is a requirement, not advisory guidance.

- Self-documenting names, obvious command usage, and well-known config keys need
  no comment.
- Comments that restate what the code does must be removed from new and modified
  code.
- **When code is removed, remove its comments.** A comment explaining something
  that no longer exists creates confusion about what it refers to. Do not leave
  orphaned explanations behind.

```bash
# Bad — restates the command
# Load nvm
export NVM_DIR="$HOME/.nvm"

# Bad — restates the alias
# List files with color
alias ls='ls --color=auto'
```

## Deferred-work markers

`# TODO` and `# FIXME` are acceptable without a ticket reference. Link a GitHub
Issue when one exists.

```bash
# TODO: switch to mise once the Ruby plugin stabilizes (broken on macOS arm64)
# TODO(#42): restore after the upstream font rendering fix lands
```

## Comments vs. commit messages

Comments are for context needed **while reading the file** — ongoing rationale,
constraints, cross-references. One-time context about how a change was made
belongs in the commit message. Workaround references belong in code because the
workaround is an ongoing constraint, not a historical event.
