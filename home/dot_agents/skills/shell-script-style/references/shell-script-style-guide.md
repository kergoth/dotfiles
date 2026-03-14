# Shell Script Style Guide

This document captures preferred Bash/POSIX shell scripting style.

## Interpreter and Safety

- Bash scripts start with `#!/usr/bin/env bash` and `set -euo pipefail`.
- POSIX sh scripts use `#!/bin/sh` and `set -eu` (no `pipefail`).
- Blank line rules:
  - No blank line between shebang and top-of-file comments.
  - Blank line between the last top-of-file comment block and code.
  - If there are no top-of-file comments, blank line between shebang and code.

## File Structure

**Note on script complexity**: The guidance below applies to scripts of moderate to high complexity. For extremely simple scripts (e.g., simple filters that only process stdin/stdout with no arguments, single-command wrappers), it's acceptable to skip the full structure (argument parsing, verbosity handling, `main()` function, etc.) and keep the script minimal. Use your judgment - if the script is just a shebang and a simple command or pipeline, the full structure is unnecessary overhead.

- Include a `usage()` or `show_help()` function at the top before all other functions.
- Use `main()` as the entry point and keep top-level code minimal.
- Argument parsing lives in a dedicated `process_arguments()` function called from `main "$@"`.
- For scripts that need the script's directory, use a global `scriptdir` variable.
- **Bash scripts**: Use `BASH_SOURCE[0]` which is more reliable than `$0`:
  ```bash
  scriptdir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
  ```
- **POSIX sh scripts**: Note that `$0` isn't guaranteed to be absolute. For better portability, handle both absolute and relative paths:
  ```bash
  # Portable POSIX approach (avoids readlink -f which isn't available on macOS)
  if [ -z "${0##/*}" ]; then
      # $0 is absolute
      scriptdir=$(cd "$(dirname "$0")" && pwd -P)
  else
      # $0 is relative, try to find it in PATH
      script=$(command -v "${0##*/}") || script="$0"
      scriptdir=$(cd "$(dirname "$script")" && pwd -P)
  fi
  ```
- **Note on `readlink -f`**: While sometimes used for convenience (especially when you know you have a more capable environment), `readlink -f` isn't portable to most macOS systems. The POSIX approach above avoids this dependency, though it has limitations if the script's PATH differs from the caller's PATH.
- For scripts that need to reference the script name in multiple places (beyond just usage/help text), use a global `scriptname` variable:
  - **Bash scripts**: Use `BASH_SOURCE[0]` for consistency:
    ```bash
    scriptname=${BASH_SOURCE[0]##*/}
    ```
  - **POSIX sh scripts**: Use `$0`:
    ```bash
    scriptname=${0##*/}
    ```

## Comments

- Prefer minimal comments. Only add comments when they truly add clarity or necessary context.
- Avoid comments that restate what the code obviously does.
- Use comments to explain the "why" behind unusual code or decisions that can't be derived from context.
- Use simple comments. Avoid decorative comment blocks with `=====` or similar separators.
- For usage/help text, place it in comments at the top of the script and extract it:
  ```bash
  # Usage: script-name [options] args
  #
  # Description of what the script does.
  #
  # Options:
  #     -x VALUE    Script-specific options (list all script-specific options first)
  #     -n          Dry run, don't actually do anything
  #     -v          Increase verbosity, can be specified multiple times
  #     -q          Decrease verbosity, can be specified multiple times
  #     -h          Show this help message
  ```
  The description should appear between the `Usage:` line and the `Options:` line so it is included when the usage is displayed. Extract from `Usage:` through `Options:` and then from `Options:` through the `-h` option.

  **Option ordering:** List script-specific options first, followed by standard options in this order: `-n`, `-v`, `-q`, `-h`.

## Argument Parsing

- Prefer `getopts` for argument parsing (built-in, portable, simple).
- Use `getopt` only when long argument support (`--long-option`) is needed.
- Parse arguments in dedicated `process_arguments()` function.
- Place `process_arguments()` immediately after `usage()` or `show_help()` to keep the usage comments and the implementation that uses them close together for easier maintenance.
- Always support `-h` for help, which should call `usage()` or `show_help()` and exit 0.
- Always support `-n` for dry run mode (sets `dry_run=1`).
- Always support `-v` and `-q` as a pair for verbosity control:
  - `-v` increments verbosity (can be specified multiple times)
  - `-q` decrements verbosity (can be specified multiple times)
  - Use a numeric `verbosity` variable, starting at 0
  - Example: `v) verbosity=$((verbosity + 1)) ;;` and `q) verbosity=$((verbosity - 1)) ;;`
- Handle unknown options by showing usage and exiting with error:
  ```bash
  \?)
      echo "Unknown option: -$OPTARG" >&2
      usage >&2
      exit 1
      ;;
  ```
- Extract help text from comments when using `show_help()`:
  ```bash
  show_help() {
      sed -n '/^# Usage:/,/^# *-h /p' "$0" | sed 's/^# *//'
  }
  ```

-## Saving and Restoring Arguments (POSIX sh only)

- When a POSIX sh wrapper needs to consume only some arguments but later replay or reorder the remainder, saving and restoring the positional args can help keep the logic linear.
- Use the `saved` string and `eval set -- "$saved"` approach rather than manipulating `$@` directly; bash scripts should prefer arrays instead.
  ```bash
  quote(){
      sed -e "s,','\\\\'',g; 1s,^,',; \$s,\$,',;" <<'EOF'
$1
EOF
  }

  save () {
      case "$1" in
      *\'*)
          saved="$saved $(quote "$1")"
          ;;
      *)
          saved="$saved '$1'"
          ;;
      esac
  }

  # Usage pattern:
  saved=""
  while [ $# -gt 0 ]; do
      case "$1" in
      --keep)
          shift
          ;;
      *)
          save "$1"
          shift
          ;;
      esac
  done

  eval set -- "$saved"
  ```
- Quote the captured arguments carefully as shown so `eval set --` may restore them faithfully.

## Formatting

- 4-space indentation.
- Avoid dense one-liners and semicolon chains.
- Prefer multi-line `if` statements.
- Redirection operators: no space between operator and target (`>/dev/null`, `2>&1`, `>>file`).
  - Exception: When redirecting stdin with `<`, a space may be used for clarity in complex commands, but no space is also acceptable.

## Variable Practices

- Avoid unnecessary quoting in assignments:
  - `a=true`, `b=`, `c=$(some command)`
- Boolean flags use `1` and `0`, checked with `-eq` / `-ne`.
- Use lowercase with underscores for multi-word variable names: `dry_run`, `verbosity`, `config_file`.
- Prefer shorter variable names unless there's real clarity added by length.
- Avoid camelCase in variable names.
- Only use uppercase in variable names for globals, and even then primarily for exported variables, not global state.
- One variable per line in declarations at the start of each function.
- Prefer `local var=value` over `local var` followed by `var=value`, except when the value uses command substitution `$()` which would suppress error codes with `set -e`.

## Temporary Files and Cleanup

- Don't create temporary files in functions. Dealing with cleanup and signal handlers in functions isn't particularly portable and is often error prone.
- Instead, create a global `tmpdir` with an EXIT signal handler to clean up the entire folder unconditionally:
  ```bash
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT
  ```
- **Signal handling complexity**: Handling interrupts (INT/TERM) in shell scripts is complex. Anything checking child process exit codes needs to explicitly check for interruption/termination, as the child may catch the signal but the parent might not, or they may receive the handler at different times. While INT/TERM traps have been used before (e.g., `trap 'trap - INT; kill -INT $$ &>/dev/null' INT`), more investigation is necessary to consider best practices. If signal handling becomes a serious issue, that's an indicator it's time to switch to Python instead of shell.
- **Exception for atomic operations**: When downloading or unpacking artifacts to a destination, it's appropriate to create the tmpdir relative to the destination (in the same parent directory) rather than using a global tmpdir. This ensures atomic renames work correctly, as renames across filesystems are not atomic. **Important**: Setting a trap in a function overrides any global trap for that signal. If your script already uses a global EXIT trap, you **must** use a subshell to avoid overriding it:
  ```bash
  # Preferred: If global EXIT trap already exists, use subshell:
  (
      parent="$(dirname -- "$dest_dir")"
      tmpdir="$(mktemp -d -p "$parent" ".myapp.download.XXXXXX")"
      trap 'rm -rf -- "$tmpdir"' EXIT

      # Download/unpack to tmpdir, then atomically rename to final location
  )

  # Alternative: Use cleanup array with single global trap (avoid unless necessary):
  cleanup_dirs=()
  trap 'rm -rf -- "${cleanup_dirs[@]}"' EXIT

  # In functions that need tmpdir:
  parent="$(dirname -- "$dest_dir")"
  tmpdir="$(mktemp -d -p "$parent" ".myapp.download.XXXXXX")"
  cleanup_dirs+=("$tmpdir")

  # If no global EXIT trap exists, function-scoped trap is acceptable:
  parent="$(dirname -- "$dest_dir")"
  tmpdir="$(mktemp -d -p "$parent" ".myapp.download.XXXXXX")"
  trap 'rm -rf -- "$tmpdir"' EXIT
  # ... (but be aware this pattern precludes adding a global trap later)
  ```
- Then create temporary files within `$tmpdir` using simple, descriptive names:
  ```bash
  tempfile="$tmpdir/config"
  ```

## Messaging Functions

- Use `msg_` prefixed functions for output:
  - `msg()` - Basic printf wrapper that outputs to stderr:
    ```bash
    msg() {
        fmt="$1"
        if [ $# -gt 1 ]; then
            shift
        fi
        # shellcheck disable=SC2059
        printf "$fmt\n" "$@" >&2
    }
    ```
  - `msg_color()` - Color support with NO_COLOR/COLOR checks:
    ```bash
    msg_color() {
        local color=$1
        shift
        local msg=$1
        shift
        # shellcheck disable=SC2059
        if [ -n "${NO_COLOR:-}" ] || { [ -z "${COLOR:-}" ] && ! [ -t 1 ]; }; then
            printf "${msg}\n" "$@" >&2
            return
        else
            printf "\033[${color}m${msg}\033[0m\n" "$@" >&2
        fi
    }
    ```
  - `msg_blue()`, `msg_green()`, `msg_red()`, `msg_yellow()` - Color variants using `msg_color()`.
  - `msg_verbose()` - Shows when `verbosity > 0`:
    ```bash
    msg_verbose() {
        if [ "${verbosity:-0}" -gt 0 ]; then
            msg_yellow "$@"
        fi
    }
    ```
  - `msg_debug()` - Shows when `verbosity > 1`:
    ```bash
    msg_debug() {
        if [ "${verbosity:-0}" -gt 1 ]; then
            msg "$@"
        fi
    }
    ```
  - `msg_verydebug()` - Shows when `verbosity > 2` (optional, for very verbose output).
  - `die()` - Error message and exit:
    ```bash
    die() {
        msg_red "$@"
        exit 1
    }
    ```

## Command Execution

- Use a `run()` function pattern to enable easily showing executed commands for `-v` or `-vv`:
  ```bash
  run() {
      if [ "${dry_run:-0}" = "1" ] || [ "${verbosity:-0}" -gt 0 ]; then
          printf '❯ %s\n' "$(printcmd "$@")" >&2
      fi
      if [ "${dry_run:-0}" != "1" ]; then
          "$@" || return $?
      fi
  }
  ```
- Use `printcmd` (or equivalent) to format commands for display. This can be a Python helper:
  ```python
  #!/usr/bin/env python3
  import subprocess
  import sys
  print(subprocess.list2cmdline(sys.argv[1:]))
  ```
- For commands that should always run (not subject to dry-run), use `run_always()`:
  ```bash
  run_always() {
      local ret=0
      if [ "${verbosity:-0}" -gt 0 ]; then
          printf '❯ %s\n' "$(printcmd "$@")" >&2
      fi
      "$@" || ret=$?
      return $ret
  }
  ```

## Control Practices

- Allow `|| true` only when intentionally masking errors.
- Avoid `[[ … ]] && action` with `set -e`.

## Function Practices

- Use local variables inside all functions.
- Avoid trivial wrapper functions around obvious commands.

## File System and State

- Prefer XDG directories for cache/state.
