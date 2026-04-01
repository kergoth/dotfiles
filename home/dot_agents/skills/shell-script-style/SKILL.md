---
name: shell-script-style
description: Apply Christopher Larson's preferred Bash and POSIX shell script style when creating or substantially editing user-facing shell scripts. Use when writing or modifying shell utilities under `scripts/` or `script/` (including extensionless shebang executables, pre-commit entry scripts, and CI helpers), `.sh` files, shell snippets intended for the user to keep, or any Bash or POSIX sh program that will become part of the maintained codebase. Do not use for temporary test scripts, disposable intermediate artifacts, or scripts written solely for AI-agent execution.
---

# Shell Script Style

## Overview

Use this skill to keep user-owned shell scripts aligned with the local shell style guide. Read the bundled reference before writing code, then apply the guide proportionally to the script's complexity.

## Workflow

1. Decide whether the script is user-facing. If it is a temporary harness, scratch file, or agent-only helper, skip this skill.
2. Decide whether the script should be `bash` or POSIX `sh`. Prefer `bash` unless portability requirements clearly call for `sh`.
3. Read [`references/shell-script-style-guide.md`](references/shell-script-style-guide.md) before drafting or revising the script.
4. Apply the guide with judgment:
   - Use the full structure for moderate or complex scripts.
   - Keep genuinely tiny wrappers or filters minimal when the guide explicitly allows it.
   - Skip `process_arguments()` for scripts that only forward positional arguments (no switches/dry-run knobs) to another tool (e.g., `@/Users/kergoth/bin/list-chezmoi-repos`) and, more generally, for “hello world”–style utilities that only consume arguments/produce output without any options to encode.
5. Before finishing, verify the script still matches the guide's defaults for safety flags, formatting, argument parsing, messaging helpers, and dry-run or verbosity behavior where applicable.

## Non-Negotiables

- Use `#!/usr/bin/env bash` with `set -euo pipefail` for Bash scripts.
- Use `#!/bin/sh` with `set -eu` for POSIX `sh` scripts.
- In Bash scripts use `BASH_SOURCE[0]` (not `$0`) for `scriptdir` and `scriptname`; POSIX `sh` scripts use `$0`.
- Prefer `main()` plus `process_arguments()` and `usage()` for non-trivial scripts.
- Prefer `getopts`, support `-h`, and include `-n`, `-v`, and `-q` when the script performs meaningful actions.
- Use 4-space indentation, avoid dense one-liners, and keep comments minimal.
- Prefer `msg_*` output helpers and a `run()` wrapper when the script benefits from dry-run or verbosity control.

## Scope Boundary

Apply this skill when the output is meant to be read, run, or maintained by the user. Scripts committed to a repository under `scripts/`, `.devcontainer/scripts/`, or similar developer-tooling paths — including pre-commit helpers and CI utilities — are user-facing; apply this skill unless they are explicitly disposable or agent-only. Do not apply it to:

- throwaway reproduction scripts
- temporary test fixtures or harnesses
- one-off migration snippets embedded only in the current session
- agent-internal helper scripts that are not becoming part of the user's maintained files

When a shell task becomes complex enough that signal handling, data modeling, or cleanup semantics are getting brittle, prefer recommending Python instead of forcing the logic into shell.

## Reference

The canonical guidance lives in [`references/shell-script-style-guide.md`](references/shell-script-style-guide.md). Treat that file as the source of truth for detailed conventions and examples.
