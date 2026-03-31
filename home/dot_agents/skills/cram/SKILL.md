---
name: cram
description:
  Guide for writing, reading, and debugging cram functional tests (.t files).
  Use this when working with cram test files, creating new .t tests, debugging
  test failures, understanding cram output diffs, or when you encounter exit
  code 80 or .err files from test runs. Also use when the user mentions cram,
  .t files, or transcript-style shell tests.
---

# Cram

Cram is a functional testing framework for command-line programs. Tests are
`.t` files that read like shell session transcripts — commands, expected output,
and documentation all in one file.

## Core Syntax

```
This is a comment — any unindented line is documentation.

  $ command to execute
  expected output line
  output matched as glob (glob)
  output matched as regex (re)
  line without trailing newline (no-eol)
  escaped unprintable chars \x1b[0m (esc)
  [1]

  $ multiline command \
  > continued here with the > prefix
  output from the multiline command
```

**Indentation rules:**
- 2-space indent + `$ ` = shell command
- 2-space indent + `> ` = continuation of previous command (shell PS2 prompt)
- 2-space indent (no prefix) = expected output
- No indent = comment/documentation

**Exit codes:** A non-zero exit code appears as `[N]` on its own line as the
last expected output. Exit code 0 is implicit and never shown.

## Output Matching

Cram tries **literal match first**, then falls back to the annotated mode:

| Suffix | Meaning |
|--------|---------|
| *(none)* | Exact literal match |
| `(re)` | Perl-compatible regex |
| `(glob)` | Glob pattern (`*`, `?`; escape with `\`) |
| `(no-eol)` | Line has no trailing newline |
| `(esc)` | Line contains escaped unprintable characters |

Combine when needed: a line can end with `(re)` and use regex to match escaped
output, etc.

## Skipping Tests

**Exit code 80 means "skip this test."** Cram marks it with `s` in output and
does not count it as a failure. Use this for conditional tests:

```
  $ command -v some-tool > /dev/null 2>&1 || exit 80
  $ some-tool --version
  some-tool 1.2.3
```

**Exit code 80 skips the entire `.t` file**, not just the remaining commands.
If you only want to skip part of a test file, split it into separate `.t` files
and put the skip guard in the one that needs it.

Empty test files are also treated as skipped.

## Test Environment

Each test runs in a fresh temporary directory. Key variables provided:

| Variable | Value |
|----------|-------|
| `$TESTDIR` | Directory containing the `.t` file |
| `$TESTFILE` | Basename of the current `.t` file |
| `$TESTSHELL` | Shell path (from `--shell`) |
| `$CRAMTMP` | Test runner's temporary directory |
| `$TMPDIR` | Same temp directory (also `$TEMP`, `$TMP`) |

Cram **resets** these environment variables before each test to ensure
reproducibility:

| Variable | Reset to |
|----------|----------|
| `LANG`, `LC_ALL`, `LANGUAGE` | `C` |
| `TZ` | `GMT` |
| `COLUMNS` | `80` |
| `CDPATH`, `GREP_OPTIONS` | *(empty)* |

Use `--preserve-env` / `-E` to skip these resets when testing
environment-sensitive behavior.

## Failure Output

- Failed tests produce a unified diff showing expected vs actual output
- A `.err` file is written alongside the `.t` file with the actual output
- Use `cram -i` (interactive) to merge actual output back into the `.t` file —
  useful for bootstrapping new tests or updating after intentional changes

**Bootstrapping expected output:** Run the command manually until it produces
correct output, then run `cram -i yourtest.t`. Cram will prompt you to accept
the actual output as the new expected output — no manual transcription needed.
This is the standard way to create tests for existing working commands.

## Common Patterns

### Source helpers from test directory

```
  $ source "$TESTDIR/helpers.sh"
```

### Normalize variable output

```
  $ date +%Y
  \d{4} (re)
```

### Match paths across platforms

```
  $ echo "$HOME/some/path"
  */some/path (glob)
```

### Guard on tool availability

```
  $ command -v jq > /dev/null 2>&1 || exit 80
  $ echo '{"a":1}' | jq .a
  1
```

## Pitfalls

- **Commands that read stdin** (like `ssh`) can consume the test shell's stdin
  and break subsequent commands. Use `ssh -n` or redirect stdin explicitly.
- **Daemon processes** that inherit stdout without closing it will cause cram to
  hang waiting for EOF. Redirect daemon output: `daemon > /dev/null 2>&1 &`
- **zsh and COLUMNS**: `COLUMNS=80` cannot be reset when using `--shell=zsh`
  because zsh treats it specially.
- **Trailing whitespace** in expected output matters — a literal match includes
  it. If a diff shows no visible difference, check for trailing spaces.

## Further Reference

For the full CLI options, `.cramrc` configuration, and additional edge cases,
read `references/cram-reference.md` in this skill directory.
