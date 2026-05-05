---
name: cli-design
description: >
  Guidelines for designing and implementing command-line interfaces. Use when creating a new CLI
  tool, adding subcommands or flags to an existing one, implementing help text, designing error
  messages, or structuring CLI output. Also use when reviewing CLI code for usability, when the
  user asks about CLI best practices, or when generating argument parsers, config handling, or
  shell completions. Applies to any language.
---

# CLI Design Guidelines

When designing or implementing a CLI, follow these rules. They encode decades of convention
and modern best practices from [clig.dev](https://clig.dev/). Breaking a rule is fine when you
have a clear reason — but the default is to follow them.

For detailed rationale, examples, and edge cases, read specific sections of
`references/cli-guidelines.md` by topic — don't load the entire file at once. It has a table
of contents at the top; use section headers to target what you need.

## Core Principles

Design for humans first, but keep programs composable. Follow existing CLI conventions unless
breaking them clearly improves usability. Say just enough — don't hang silently, don't dump
pages of noise. Make functionality discoverable through help text, examples, and suggestions.

## Foundations

- Use an argument parsing library. Don't hand-roll flag parsing.
- Return 0 on success, non-zero on failure. Map distinct exit codes to distinct failure modes.
- Primary output to stdout. Messages, errors, progress to stderr.

## Help Text

- Support both `-h` and `--help`. Don't overload `-h`.
- When run with no args (and args are required), show concise help: what it does, an example
  or two, and a pointer to `--help`.
- For git-style tools, also support `help` as a subcommand.
- Lead with examples in help text. Users read examples first.
- Show the most common flags and subcommands first.
- Suggest corrections for typos. Ask, don't auto-execute.
- If the command expects piped stdin and stdin is a TTY, show help and exit.

## Output

- Detect TTY to decide formatting. Human-readable by default; machine-readable when piped.
- Support `--json` for structured output and `--plain` for strict line-oriented output.
- When state changes, tell the user what changed.
- Suggest what command to run next when commands form a workflow.
- Support `-q`/`--quiet` for scripts that want silence.
- Use color with intention. Disable when: not a TTY, `NO_COLOR` is set, `TERM=dumb`,
  or `--no-color` is passed.
- Disable animations when not a TTY.
- Use a pager for long output (only when interactive). Good defaults: `less -FIRX`.
- Don't output developer-only debug info by default.

## Errors

- Rewrite errors for humans. Frame them as guidance toward a fix, not raw diagnostics.
- Keep signal-to-noise high. Group similar errors.
- Put the most important information last in terminal output.
- For unexpected errors, write debug details to a file (not the terminal) and provide
  bug-reporting instructions.

## Arguments and Flags

- Prefer flags over positional args. Flags are self-documenting and extensible.
- Provide both short and long forms for all flags (`-h` / `--help`).
- Reserve single-letter flags for commonly used options.
- Use standard names: `--force`, `--dry-run`, `--quiet`, `--json`, `--output`, `--version`.
  See `references/cli-guidelines.md` §Arguments and Flags for the full table.
- Make the default behavior right for the common case. Don't hide good UX behind a flag.
- Make flags, args, and subcommands order-independent where possible.
- Never accept secrets via flags (leaks to `ps`, shell history). Use `--password-file`,
  stdin, or credential stores.

## Interactivity

- Only prompt when stdin is a TTY. In non-interactive contexts, fail with guidance on which
  flag to pass.
- Support `--no-input` to explicitly disable all prompts.
- Never require a prompt — always allow non-interactive flag/arg equivalents.
- Confirm before dangerous actions. Scale confirmation to danger level: mild (optional),
  moderate (prompt + dry-run), severe (require typing the resource name).
- Support `-` to mean stdin/stdout for file arguments.

## Subcommands

- Be consistent across subcommands: same flag names, same output formatting.
- Use consistent noun-verb or verb-noun ordering across all object types.
- Don't have ambiguous names (e.g., "update" vs. "upgrade").

## Robustness

- Validate input early. Fail before side effects.
- Print something within 100ms. Before network requests, say what you're about to do.
- Show progress for long operations. Use a progress-bar library, not custom code.
- Set network timeouts. Have a reasonable default.
- Make operations recoverable — re-running after failure should resume, not restart.
- Design for crash-only operation where possible: no mandatory cleanup.

## Configuration

Apply config in this precedence (highest to lowest):
1. Flags
2. Environment variables
3. Project-level config (`.env`)
4. User-level config
5. System-wide config

- Follow the XDG Base Directory Spec for config file locations.
- Ask consent before modifying config you don't own.

## Environment Variables

- Check standard env vars: `NO_COLOR`, `DEBUG`, `EDITOR`, `HTTP_PROXY`, `TMPDIR`, `HOME`,
  `PAGER`, `LINES`, `COLUMNS`.
- Use uppercase, numbers, underscores only. Keep values single-line.
- Read from `.env` for project-specific values, but don't use `.env` as a substitute for
  proper config files.
- Never read secrets from env vars. They leak into process state, logs, and container
  inspection.

## Naming

- Simple, memorable, lowercase word. Dashes if needed, never camelCase.
- Short but not too short. Easy to type — avoid awkward hand positions.

## Distribution

- Distribute as a single binary where possible.
- Make uninstall easy and documented right next to install instructions.

## Analytics

- Never phone home without consent. Prefer opt-in.
- Consider alternatives: instrument docs, track downloads, talk to users directly.

## Future-proofing

- Keep changes additive. Add new flags rather than changing existing ones.
- Warn before breaking changes. Tell users how to adapt.
- Don't have catch-all subcommands (blocks adding new subcommands later).
- Don't allow implicit abbreviations of subcommands (blocks adding same-prefix subcommands).
- Encourage `--plain`/`--json` in scripts so human-readable output can evolve freely.

---

## Beyond clig

The following guidance extends clig with considerations it doesn't cover. See
`references/cli-guidelines.md` §Beyond clig for details.

### Color control

Prefer `--color=always|auto|never` over a bare `--no-color` flag. This tri-state pattern
(used by `grep`, `ls`, `git`, `cargo`, `rg`, and many others) covers all use cases in a
single flag and is widely understood. `auto` (the default) enables color when the output
stream is a TTY.

Full evaluation order for color decisions:
1. `NO_COLOR` env var — if set and non-empty, disable color
2. `--color` flag — `always` forces on, `never` forces off, `auto` defers to TTY detection
3. `TERM=dumb` — disable color (when still in `auto` mode)
4. TTY detection — enable color if the output stream is a TTY (the `auto` behavior)
5. `FORCE_COLOR` env var — if set and non-empty, enable color (final override)

This supersedes the `--no-color` flag mentioned in the core clig guidance above. The
`--no-color` form is equivalent to `--color=never` and can be accepted as an alias for
compatibility, but `--color` should be the primary interface.

See `references/cli-guidelines.md` §Beyond clig for details on `FORCE_COLOR`.

### Additional environment variables

- Check `VISUAL` before `EDITOR` when prompting for multi-line input. `VISUAL` takes
  precedence by long-standing Unix convention.
- Support `FORCE_COLOR` ([force-color.org](https://force-color.org)): when set and non-empty,
  force ANSI color output. Evaluate after `NO_COLOR` and config/flags, so it acts as a
  final override. Useful for piping through pagers, CI with ANSI support, and chained programs.

### Agent-friendly design

CLI tools are increasingly consumed by AI agents, not just humans and scripts. Agents benefit
from the same structured information humans do (error explanations, state descriptions,
suggested next steps), but they consume it programmatically.

- **Progressive disclosure.** Consider supporting machine-readable help (`--help-json` or
  similar) so agents can discover capabilities without parsing human-formatted text. Structure
  commands so exploration can go narrow-to-deep: top-level overview, then subcommands, then
  details on a specific command.
- **Structured JSON errors.** When `--json` is active, error output should include
  machine-parseable fields: `type` (error category), `message` (human-readable),
  `recoverable` (whether retry makes sense), and `suggestions` (array of next actions).
- **Don't assume the consumer.** TTY detection distinguishes interactive humans from
  pipes/scripts. Agents may be either. Design so that both `--json` structured output and
  human-readable defaults carry enough context to act on.

### POSIX sh portability

When the tool is a portable shell script targeting `/bin/sh`:

- Long options (`--help`, `--verbose`) are unavailable unless you hand-roll them with `case`
  statements. Prioritize consistent, well-documented short options.
- `getopts` (the POSIX built-in) handles single-letter flags only. For anything more complex,
  use a `while/case` loop over `"$@"`.
- Many clig recommendations (argument parsing libraries, JSON output, progress bars) assume
  a full programming language. In POSIX sh, focus on the fundamentals: clear help text via
  `-h`, correct exit codes, stdout/stderr separation, and clean signal handling.
- ANSI color on a TTY is still available and should be used. `printf '\033[1m'` works in
  any POSIX sh. Respect `NO_COLOR`, `FORCE_COLOR`, and `TERM=dumb` as usual.
- For progressive capability, detect tools like `gum` at runtime for richer prompts, spinners,
  and formatted output on capable systems, but always provide plain fallbacks.
