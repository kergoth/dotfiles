# CLI Design Guidelines Reference

Adapted from [clig.dev](https://clig.dev/) (Command Line Interface Guidelines).
This is an agent-oriented distillation: same substance, imperative form, no narrative.
Read specific sections as needed; don't load the entire file unless doing a comprehensive review.

## Table of Contents

- [Principles](#principles)
- [The Basics](#the-basics)
- [Help](#help)
- [Documentation](#documentation)
- [Output](#output)
- [Errors](#errors)
- [Arguments and Flags](#arguments-and-flags)
- [Interactivity](#interactivity)
- [Subcommands](#subcommands)
- [Robustness](#robustness)
- [Future-proofing](#future-proofing)
- [Signals and Control Characters](#signals-and-control-characters)
- [Configuration](#configuration)
- [Environment Variables](#environment-variables)
- [Naming](#naming)
- [Distribution](#distribution)
- [Analytics](#analytics)
- [Beyond clig](#beyond-clig)

---

## Principles

These shape trade-off decisions when rules conflict.

**Human-first design.** If a command is used primarily by humans, design for humans first.
Many CLI conventions carry legacy assumptions from an era when programs were consumers of other
programs' output. Modern CLIs are text-based UIs.

**Simple parts that work together.** Programs should be composable via stdin/stdout, exit codes,
and signals. Plain line-based text is the universal interchange format; JSON when structure is
needed. Your program will become part of a larger system whether you plan for it or not.

**Consistency across programs.** Follow patterns that already exist. CLI conventions are muscle
memory. Breaking them costs users cognitive overhead. Break convention only with intention and
clear benefit.

**Say just enough.** Too little output (hanging silently) and too much (pages of debug spew)
both leave users confused. Err toward less, but never toward silent.

**Ease of discovery.** Help texts, examples, suggested next commands, and actionable error
messages all reduce the need to leave the terminal. Steal discoverability ideas from GUIs.

**Robustness.** Handle unexpected input gracefully. Idempotent operations where possible.
Keep users informed. No scary stack traces in normal operation. Simplicity contributes to
robustness.

**Empathy.** Give users the feeling you are on their side. Exceed expectations. This starts with
caring about error messages, help text, and the small details.

---

## The Basics

**Use a command-line argument parsing library.** Either the language's built-in one or a
well-regarded third-party one. They handle argument parsing, flag handling, help text generation,
and spelling suggestions correctly. Look up current best options for your target language rather
than hand-rolling.

**Return zero exit code on success, non-zero on failure.** Exit codes are how scripts determine
success or failure. Map distinct non-zero codes to the most important failure modes.

**Send primary output to stdout.** All machine-readable output goes to stdout. This is where
piping sends things by default.

**Send messaging to stderr.** Log messages, errors, progress indicators, and diagnostics go to
stderr. This keeps them visible to the user when stdout is piped to another command.

---

## Help

**Display help for `-h` and `--help`.** Both flags should work. Ignore other flags and arguments
when help is requested — the user should be able to append `-h` to any invocation.
Don't overload `-h` for anything else.

**Display concise help when run with no arguments (if arguments are required).** Include:
- A description of what the program does
- One or two example invocations
- Descriptions of flags (unless there are many)
- An instruction to pass `--help` for more detail

Example (`jq`):
```
$ jq
jq - commandline JSON processor [version 1.6]

Usage:    jq [options] <jq filter> [file...]

jq is a tool for processing JSON inputs, applying the given filter
to its JSON text inputs and producing the filter's results as JSON
on standard output.

For a listing of options, use jq --help.
```

**For git-style tools, also support `help` as a subcommand:**
```
$ myapp help
$ myapp help subcommand
$ myapp subcommand --help
$ myapp subcommand -h
```

**Provide a support path.** Include a website or issue tracker link in top-level help text.

**Link to web documentation from help text.** If a subcommand has a dedicated docs page, link
directly to it.

**Lead with examples.** Users reach for examples before other documentation. Show common and
complex uses first. Include actual output if it helps and isn't too long. Build from simple to
complex use cases.

**Put exhaustive examples elsewhere** if there are many — a cheat sheet subcommand or web page.
Don't bloat help text.

**Display common flags and commands first.** `git` does this well: "getting started" and
frequently used subcommands appear before the full list.

**Use formatting in help text.** Bold headings improve scannability. Use terminal-independent
formatting so users don't see raw escape sequences.

**Suggest corrections when input looks like a typo.**
```
$ brew update jq
Error: This command updates brew itself. Use `brew upgrade jq` to upgrade a formula.
```

You can ask whether to run the suggestion, but don't auto-execute — typos and logical mistakes
are different things, and auto-executing trains users to rely on syntax you'll need to support
forever.

**If the command expects piped stdin and stdin is a TTY, show help and quit.** Don't hang
silently like `cat` does.

---

## Documentation

**Provide web-based documentation.** Searchable, linkable, inclusive.

**Provide terminal-based documentation.** Fast to access, stays in sync with the installed
version, works offline.

**Consider man pages.** Many users reflexively try `man mycmd`. If you provide man pages, also
make them accessible via a `help` subcommand (e.g., `npm help ls` = `man npm-ls`).
Tools like `ronn` can generate both man pages and web docs from the same source.

---

## Output

**Human-readable output is paramount.** Detect whether stdout/stderr is a TTY to decide on
formatting. Use your language's TTY detection utility.

**Support machine-readable output without degrading human output.** Programs should produce
output that pipes well to `grep` and other line-oriented tools.

**Use `--plain` for strict machine-readable tabular output** when human-readable formatting
(e.g., multi-line table cells) would break line-oriented tooling.

**Support `--json` for structured output.** JSON integrates with `jq` and the broader ecosystem
of JSON tools, and pipes directly to/from web services via `curl`.

**Display output on success, but keep it brief.** Silent completion (the old UNIX default)
confuses human users. Err toward less, but not toward nothing. Provide `-q`/`--quiet` for
scripts that want silence.

**When you change state, tell the user what changed.** Help them model the system's state.
Example: `git push` reports exactly what it did and the new state of the remote branch.

**Make current state easy to inspect.** If your program manages complex state not visible in
the filesystem, provide a status command. Example: `git status` shows branch state, staged
changes, and hints about next steps.

**Suggest next commands.** When several commands form a workflow, tell the user what they can
run next. `git status` does this with hints like "use git add to stage changes."

**Be explicit about actions crossing program boundaries.** Reading/writing files not passed as
arguments, making network requests — these should be visible to the user (unless it's internal
state like a cache).

**Use color with intention.** Highlight important information; use red for errors. Don't
overcolor — if everything is colored, color means nothing.

**Disable color when:**
- stdout/stderr is not a TTY (check each stream independently)
- `NO_COLOR` env var is set and non-empty
- `TERM=dumb`
- `--no-color` flag is passed
- Optionally support `MYAPP_NO_COLOR` for program-specific control

**Disable animations when stdout is not a TTY.** Prevents progress bars from becoming noise
in CI logs.

**Use symbols and emoji sparingly.** They can add structure and draw attention, but overuse
makes a program feel cluttered or toylike.

**Don't output developer-only information by default.** Internal debug info should require
verbose mode. Get usability feedback from people outside the project.

**Don't treat stderr as a log file.** No log-level labels (`ERR`, `WARN`) or extraneous
context in default output. Reserve that for verbose mode.

**Use a pager for long output.** Like `git diff` does. Only when stdin/stdout is a TTY.
Good `less` options: `less -FIRX` (don't page if content fits one screen, case-insensitive
search, enable color, leave content on screen on quit).

---

## Errors

**Catch errors and rewrite them for humans.** Frame error messages as a conversation guiding
the user toward a fix.
Example: `"Can't write to file.txt. You might need to make it writable by running 'chmod +w file.txt'."`

**Maintain signal-to-noise ratio.** Group similar errors under a single header rather than
printing many similar lines. The more irrelevant output, the longer it takes to find the
real problem.

**Put the most important information last.** That's where the eye lands in terminal output.
Use red intentionally and sparingly.

**For unexpected errors, provide debug info and bug-reporting instructions.** But respect
signal-to-noise: consider writing the debug log to a file rather than dumping it to the
terminal. Pre-populate bug report URLs with available context to make reporting effortless.

---

## Arguments and Flags

**Terminology:**
- *Arguments* (args): positional parameters. Order matters. E.g., `cp foo bar`.
- *Flags*: named parameters with `-` or `--` prefix. Order generally doesn't matter.
  May take values: `--file foo.txt` or `--file=foo.txt`.

**Prefer flags to args.** Flags are self-documenting and easier to extend without breaking
existing usage.

**Provide full-length versions of all flags.** Both `-h` and `--help`. Long flags are
self-documenting in scripts.

**Reserve single-letter flags for commonly used options,** especially at the top level with
subcommands. Conserve the short-flag namespace.

**Multiple args are fine for the same type of thing.** E.g., `rm file1.txt file2.txt` — works
with globbing too.

**Two or more args for different things is usually wrong.** Exception: very common primary
actions where brevity justifies memorization, like `cp <source> <destination>`.

**Use standard flag names where conventions exist:**

| Flag | Meaning | Examples |
|------|---------|----------|
| `-a`, `--all` | All | `ps`, `fetchmail` |
| `-d`, `--debug` | Debug output | |
| `-f`, `--force` | Force (skip confirmations) | `rm -f` |
| `--json` | JSON output | |
| `-h`, `--help` | Help (only this) | |
| `-n`, `--dry-run` | Dry run | `rsync`, `git add` |
| `--no-input` | Disable prompts | |
| `-o`, `--output` | Output file | `sort`, `gcc` |
| `-p`, `--port` | Port | `psql`, `ssh` |
| `-q`, `--quiet` | Less output | |
| `-u`, `--user` | User | `ps`, `ssh` |
| `--version` | Version | |
| `-v` | Verbose or version (ambiguous — consider `-d` for verbose) | |

**Make the default the right thing for most users.** If the better behavior isn't the default,
most users will never find the flag. Design defaults for the common case.

**Prompt for missing input when interactive.** If a required argument isn't provided, prompt
for it — but never *require* a prompt. Always allow flags/args to supply everything
non-interactively. Skip prompts when stdin is not a TTY.

**Confirm before dangerous actions.** Prompt for `y`/`yes` interactively, or require
`-f`/`--force` in scripts. Scale confirmation difficulty to danger level:
- *Mild* (delete a file): optional confirmation
- *Moderate* (delete a directory, remote resource): prompt + offer dry-run
- *Severe* (delete entire application/server): require typing the resource name, or
  `--confirm="name-of-thing"` for scriptability

Watch for non-obvious destruction (e.g., changing a count from 10 to 1 implicitly deletes
9 things).

**Support `-` for stdin/stdout.** When input or output is a file, let `-` mean stdin or stdout:
```
$ curl https://example.com/something.tar.gz | tar xvf -
```

**Allow a special word like "none" for optional flag values.** E.g., `ssh -F none` for no config
file. Don't use blank values — they create ambiguity.

**Make arguments, flags, and subcommands order-independent where possible.** Users commonly
recall a previous command and add a flag at the end. Don't make flag position relative to
subcommands matter unless your parser forces it.

**Never read secrets from flags.** Flag values leak into `ps` output and shell history. Accept
secrets via `--password-file`, stdin, or other IPC mechanisms.

---

## Interactivity

**Only use prompts if stdin is a TTY.** Otherwise fail with a message telling the user which
flag to pass.

**Support `--no-input` to explicitly disable all prompts.** Fail with guidance if input is
required.

**Don't echo passwords.** Turn off terminal echo. Use your language's helpers for this.

**Let the user escape.** Make it clear how to quit. Ctrl-C should always work for network I/O.
For wrapper programs where Ctrl-C passes through (ssh, tmux), document the escape mechanism.

---

## Subcommands

**Be consistent across subcommands.** Same flag names for the same things, similar output
formatting.

**Use consistent noun-verb or verb-noun naming across object types.** E.g.,
`docker container create`, `docker volume create`. Either ordering works; `noun verb` is
more common. Keep the same verbs across different object types.

**Don't have ambiguous or similarly-named commands.** "update" vs. "upgrade" confuses users.
Disambiguate with different words or qualifying terms.

---

## Robustness

**Validate user input early.** Bail out before anything bad happens. Make validation errors
understandable.

**Responsive > fast.** Print something within 100ms. Before any network request, tell the user
what you're about to do.

**Show progress for long operations.** A spinner or progress bar makes a program *feel* faster.
Show estimated time remaining or at least an animated element so the user knows it hasn't hung.
Use established progress-bar libraries for your language.

**Parallelize where possible, but manage output carefully.** Don't let parallel output
interleave confusingly. Use libraries that support multiple progress bars (e.g., tqdm, 
schollz/progressbar). If parallel operations error, make sure logs are still accessible.

**Set network timeouts.** Allow configuration, but have a reasonable default. Don't hang
forever.

**Make operations recoverable.** After a transient failure, hitting up-arrow and enter should
resume from where it left off, not restart from scratch.

**Make it crash-only.** If you can avoid cleanup requirements (or defer cleanup to the next
run), the program can exit immediately on failure or interruption. This improves both
robustness and responsiveness.

**Expect misuse.** Users will wrap your program in scripts, run it on bad connections, run
multiple instances simultaneously, and use it in environments you didn't test.

---

## Future-proofing

**Keep changes additive.** Add new flags rather than modifying existing ones
incompatibly — as long as it doesn't bloat the interface.

**Warn before breaking changes.** When you must break an interface, warn users in advance
within the program itself. Tell them how to update their usage. Stop warning once they've
adapted.

**Changing human-readable output is OK.** Encourage `--plain` or `--json` in scripts to keep
machine-consumed output stable.

**Don't have a catch-all subcommand.** If `mycmd foo` falls through to a default subcommand
when `foo` isn't recognized, you can never add a `foo` subcommand without breaking existing
scripts.

**Don't allow arbitrary abbreviations of subcommands.** If `mycmd i` works as an alias for
`mycmd install`, you've committed to never adding another `i`-prefixed subcommand. Explicit
aliases are fine; implicit prefix matching is a trap.

**Don't create time bombs.** Will your command still work in 20 years, or does it depend on
a server you maintain? Don't build in dependencies on external services that aren't essential
to function.

---

## Signals and Control Characters

**On Ctrl-C (SIGINT), exit as soon as possible.** Print something immediately before starting
cleanup. Timeout cleanup so it can't hang forever.

**On second Ctrl-C during cleanup, skip cleanup.** Tell the user what will happen if they
hit Ctrl-C again, especially if it's destructive.
```
$ docker-compose up
…
^CGracefully stopping... (press Ctrl+C again to force)
```

**Expect unclean starts.** Your program should handle being started when cleanup from a
previous run didn't complete.

---

## Configuration

Configuration falls into three categories based on how frequently it changes:

1. **Per-invocation** (debug level, dry-run): use flags; optionally env vars too.
2. **Per-environment** (proxy, color prefs, paths): use flags + env vars. Users may set
   these in shell profiles or project `.env` files.
3. **Per-project, all users** (build config, container definitions): use a version-controlled
   config file.

**Follow the XDG Base Directory Specification.** Store config in `~/.config/` rather than
proliferating dotfiles in `$HOME`. See the
[full spec](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html).

**Ask consent before modifying config you don't own.** Prefer creating new config files
(e.g., `/etc/cron.d/myapp`) over appending to existing ones. If you must append, use dated
comments to delimit your additions.

**Apply configuration in this precedence order** (highest to lowest):
1. Flags
2. Environment variables (running shell)
3. Project-level config (e.g., `.env`)
4. User-level config
5. System-wide config

---

## Environment Variables

**Env vars are for context-dependent behavior.** They represent the terminal session's
environment: they may vary per invocation, per machine, or per project.

**Use only uppercase letters, numbers, and underscores.** Don't start with a number.

**Keep values single-line.** Multi-line values cause problems with `env` and other tools.

**Don't commandeer widely used names.** Check the
[POSIX standard env vars](https://pubs.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap08.html).

**Check standard env vars where applicable:**
- `NO_COLOR` — color control
- `DEBUG` — verbose output
- `EDITOR` — when prompting for multi-line input
- `HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY`, `NO_PROXY` — network operations
- `SHELL` — opening interactive sessions (but use `/bin/sh` for script execution)
- `TERM`, `TERMINFO`, `TERMCAP` — terminal-specific escape sequences
- `TMPDIR` — temporary files
- `HOME` — config file location
- `PAGER` — output paging
- `LINES`, `COLUMNS` — screen-size-dependent output

**Read from `.env` where appropriate** for project-specific env vars that don't change often.
But don't use `.env` as a substitute for proper config files — it has no history, only
string types, and tends to accumulate secrets insecurely.

**Do not read secrets from environment variables.** Env vars leak into process listings,
logs, `docker inspect`, and `systemctl show`. Accept secrets via credential files, pipes,
AF_UNIX sockets, or secret management services.

---

## Naming

**Make it a simple, memorable word.** Not too generic (avoid collisions with existing commands),
not too obscure.

**Use only lowercase letters, and dashes if needed.** `curl` is good; `DownloadURL` is not.

**Keep it short.** Users type it constantly. But not *too* short — the shortest names are
reserved for system utilities (`cd`, `ls`, `ps`).

**Make it easy to type.** Avoid awkward hand positions. Docker Compose was renamed from `plum`
to `fig` partly because `plum` was an awkward one-handed stretch.

---

## Distribution

**Distribute as a single binary if possible.** Use tools like PyInstaller if your language
doesn't compile to binaries natively. If you can't do a single binary, use the platform's
native package installer. Tread lightly on the user's filesystem.

Exception: language-specific tools (linters, formatters) can assume the relevant runtime is
installed.

**Make it easy to uninstall.** Put uninstall instructions right below install instructions —
that's when people most often need them.

---

## Analytics

**Do not phone home without consent.** Users expect to control their environment. Be explicit
about what you collect, why, how it's anonymized, and how long it's retained.

**Prefer opt-in over opt-out.** If you default to collecting, clearly disclose it on first run
or your website, and make disabling it easy.

**Consider alternatives to telemetry:**
- Instrument your web docs (search queries, page views)
- Instrument downloads (usage proxy, OS distribution)
- Talk to users directly (feedback channels, issue trackers)

---

## Beyond clig

The following guidance extends the clig baseline with considerations it does not cover. These
additions are clearly separated because they represent either newer conventions, different
constraints (POSIX sh portability), or an emerging design space (agent consumers) rather than
established clig content.

### Color control

The clig Output section recommends `--no-color` as a flag. In practice, most modern CLIs
have converged on a tri-state `--color` flag instead:

```
--color=always    Force color output regardless of TTY
--color=auto      Color when the output stream is a TTY (the default)
--color=never     Disable color unconditionally
```

This pattern is used by `grep`, `ls`, `git`, `cargo`, `ripgrep`, `diff`, `gcc`, and many
others. It covers all use cases in a single flag, is familiar to users, and interacts cleanly
with the environment variables below. `--no-color` can be accepted as an alias for
`--color=never` for compatibility, but `--color` should be the primary interface.

**Supersedes:** the `--no-color` flag guidance in the Output section above.

**Full evaluation order for color decisions:**

1. `NO_COLOR` env var — if set and non-empty, disable color
2. `--color` flag — `always` forces on, `never` forces off, `auto` defers to steps 3-4
3. `TERM=dumb` — disable color (when still in `auto` mode)
4. TTY detection — enable color if the output stream is a TTY (the `auto` default)
5. `FORCE_COLOR` env var — if set and non-empty, enable color (final override)

This means a user can set `NO_COLOR=1` system-wide but override it per-command with
`--color=always`, and `FORCE_COLOR` always wins when set. This ordering is consistent
with [force-color.org](https://force-color.org)'s specification.

When implementing, check each output stream (stdout, stderr) independently for TTY status.
A command may have its stdout piped while stderr remains on a terminal.

### Additional environment variables

**Check `VISUAL` before `EDITOR`.** By long-standing Unix convention, `VISUAL` specifies the
preferred visual editor and takes precedence over `EDITOR` (which historically meant a
line-mode editor like `ed`). In practice they're often set to the same value, but tools that
prompt for multi-line input should check `VISUAL` first, then fall back to `EDITOR`.

**Support `FORCE_COLOR`.** The [force-color.org](https://force-color.org) convention
complements `NO_COLOR`. When `FORCE_COLOR` is set and non-empty, force ANSI color output
regardless of TTY detection. This is useful when piping through pagers (`less -R`), in CI
environments that support ANSI, or when chaining programs where flags aren't accessible.
See the Color Control section above for the full evaluation order.

### Agent-friendly design

CLI tools are increasingly consumed by AI agents, not just humans and shell scripts. Agents
benefit from the same contextual information humans do (error explanations, state descriptions,
suggested next steps), but consume it programmatically. This creates a third audience category
beyond clig's "human vs. machine" framing.

**Progressive disclosure for agent discovery.** Consider supporting machine-readable help
(`--help-json` or similar) that exposes available commands, flags, and their descriptions as
structured data. This lets agents inspect capabilities without parsing human-formatted help
text. Structure commands so exploration can go narrow-to-deep: top-level overview, then
subcommands, then details on a specific command.

**Structured JSON errors.** When `--json` is active, error output should include
machine-parseable fields beyond just a message string:

```json
{
  "error": {
    "type": "resource_not_found",
    "message": "Project 'foo' not found",
    "recoverable": false,
    "suggestions": [
      "List available projects: mytool project list",
      "Check project name spelling"
    ]
  }
}
```

Key fields for programmatic consumers:
- `type`: machine-readable error category (not just a code number)
- `message`: human-readable explanation
- `recoverable`: whether retry makes sense (helps agents decide without parsing the message)
- `suggestions`: array of concrete next actions

This builds on clig's "catch errors and rewrite them for humans" by making the same
information available to non-human consumers.

**Don't assume the consumer.** TTY detection distinguishes interactive humans from
pipes/scripts. Agents may invoke tools either way. Design so that both `--json` structured
output and human-readable defaults carry enough context to act on. The clig advice to use
TTY detection for formatting decisions remains sound; the addition is that `--json` mode
should be as informative as human mode, not a stripped-down subset.

### POSIX sh portability

When the CLI tool is a portable shell script targeting `/bin/sh`:

- **Long options are unavailable** unless hand-rolled with `case` statements (which is fragile
  and non-standard). Prioritize consistent, well-documented short options with clear `-h`
  help text.
- **`getopts` handles single-letter flags only.** It's the POSIX built-in for option parsing.
  For anything beyond simple flags (subcommands, long options, option arguments), use a
  `while/case` loop over `"$@"`.
- **Many clig recommendations assume a full programming language.** Argument parsing libraries,
  JSON output, progress bars, and color libraries all require runtimes beyond POSIX sh. In
  shell scripts, focus on the fundamentals: clear help text via `-h`, correct exit codes,
  stdout/stderr separation, and clean signal handling (trap).
- **The clig rule "provide full-length versions of all flags" doesn't apply.** In POSIX sh with
  `getopts`, you only have short flags. This is fine — consistency and clear documentation
  matter more than long-form names.
- **ANSI color still works and should be used.** `printf '\033[1mBold\033[0m'` is valid POSIX
  sh. TTY detection (`[ -t 1 ]`), `NO_COLOR`, `FORCE_COLOR`, and `TERM=dumb` checks all work
  in shell. The absence of a color library doesn't mean the absence of color.
- **Progressive capability via optional tools.** For scripts that may run on both minimal and
  fully-equipped systems, detect tools like [`gum`](https://github.com/charmbracelet/gum) at
  runtime for richer prompts, spinners, selection menus, and formatted output. Fall back to
  plain `read`, `printf`, and simple loops when those tools aren't present. This gives a
  polished experience on capable systems without breaking portability.
