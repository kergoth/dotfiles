# Cram Full Reference

## CLI Options

| Option | Purpose |
|--------|---------|
| `-h`, `--help` | Display help |
| `-V`, `--version` | Show version |
| `-q`, `--quiet` | Suppress diff output |
| `-v`, `--verbose` | Show filenames and test status |
| `-i`, `--interactive` | Interactively merge actual output into `.t` file |
| `-d`, `--debug` | Write script output directly to terminal (bypass capture) |
| `-y`, `--yes` | Auto-answer yes to all prompts |
| `-n`, `--no` | Auto-answer no to all prompts |
| `-E`, `--preserve-env` | Skip resetting environment variables |
| `--keep-tmpdir` | Retain temporary directories after run |
| `--shell=PATH` | Shell to use (default: `/bin/sh`) |
| `--shell-opts=OPTS` | Additional shell invocation arguments |
| `--indent=NUM` | Number of spaces for indentation (default: 2) |
| `--xunit-file=PATH` | Write xUnit XML output for CI integration |

## Configuration

### `.cramrc` file

INI-style configuration under a `[cram]` section. Searched in the current
directory by default; override the path with `$CRAMRC`.

```ini
[cram]
verbose = True
indent = 4
shell = /bin/bash
```

### `CRAM` environment variable

CLI options can also be passed via the `CRAM` environment variable:

```bash
CRAM="--verbose --shell=/bin/bash" cram tests/
```

## Environment Variable Details

### Variables reset before each test

These ensure reproducible test output across environments:

| Variable | Reset to | Notes |
|----------|----------|-------|
| `TMPDIR`, `TEMP`, `TMP` | Runner's temp dir | All point to the same place |
| `LANG` | `C` | Prevents locale-dependent output |
| `LC_ALL` | `C` | Overrides all locale categories |
| `LANGUAGE` | `C` | Affects GNU gettext message catalogs |
| `TZ` | `GMT` | Prevents timezone-dependent output |
| `COLUMNS` | `80` | Terminal width for wrapping; broken with zsh |
| `CDPATH` | *(empty)* | Prevents `cd` from printing matched paths |
| `GREP_OPTIONS` | *(empty)* | Prevents deprecated grep defaults from altering output |

### Variables provided to tests

| Variable | Value |
|----------|-------|
| `CRAMTMP` | Test runner's temporary directory (parent of per-test dirs) |
| `TESTDIR` | Directory containing the `.t` file being run |
| `TESTFILE` | Basename of the current `.t` file |
| `TESTSHELL` | Path to the shell specified by `--shell` |
| `TMPDIR` | Same as `CRAMTMP` |
| `TEMP`, `TMP` | Same as `CRAMTMP` (Windows compatibility) |

## Test Result Indicators

| Symbol | Meaning |
|--------|---------|
| `.` | Test passed |
| `s` | Test skipped (empty file or exit code 80) |
| `!` | Test failed |

## Matching Mode Details

### Literal (default)

Exact byte comparison. Trailing whitespace matters. If the diff shows lines
that look identical, check for trailing spaces or tabs.

### Regex `(re)`

Perl-compatible regular expressions (Python `re` module). The pattern is
matched against the entire line. Useful for timestamps, PIDs, UUIDs, and
other variable output.

Note: the line is first tried as a literal match. If it matches literally,
the regex is never evaluated. This means `.*` on a line will literally match
`.*` in the output before falling back to regex behavior.

### Glob `(glob)`

Shell-style glob matching:
- `*` matches any string (including empty)
- `?` matches any single character
- Escape with `\*` or `\?` for literal matching

Same literal-first behavior as regex.

### Escaped `(esc)`

Marks lines containing Python-style escape sequences for unprintable
characters (e.g., `\x1b[0m` for ANSI escape codes, `\t` for tabs).
Cram automatically escapes actual output containing unprintable characters
and appends `(esc)`.

### No end-of-line `(no-eol)`

Matches output that does not end with a newline character. Common with
`printf` or commands that don't append a final newline.

## Dune Variant Differences

The OCaml build system Dune includes a cram-compatible test runner with
minor extensions:

- **Directory tests**: A `*.t/` directory containing `run.t` plus fixture
  files, instead of a single `.t` file
- **Promotion**: `dune promote` merges actual output back (equivalent to
  `cram -i`)
- **Unreachable markers**: If a command causes early shell exit, subsequent
  commands are marked `***** UNREACHABLE *****`
- **POSIX strict mode**: Uses `sh` by default; POSIX special builtins (like
  `.` / `source`) cause immediate exit on failure in non-interactive shells

## Stdin/Stdout Edge Cases

### Commands that read stdin

Commands like `ssh`, `gpg --gen-key`, or any program that reads from stdin
can consume the test shell's input stream, causing subsequent commands to be
swallowed. Mitigations:

- `ssh -n` to prevent stdin reading
- `< /dev/null` to explicitly close stdin
- Pipe from `echo` or heredoc instead of relying on tty input

### Daemon processes

A background process that inherits stdout and does not close it will prevent
cram from detecting EOF on the command's output. The test will hang
indefinitely. Always redirect daemon output:

```
  $ mydaemon > /dev/null 2>&1 &
```

### Buffered output

Programs that buffer stdout (common in Python, Ruby) may produce output in
a different order than expected when stderr is unbuffered. Use
`PYTHONUNBUFFERED=1` or `stdbuf -oL` when output ordering matters.
