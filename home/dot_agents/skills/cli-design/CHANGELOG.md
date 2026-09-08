# Changelog

This file records additions to the CLI Design skill that extend the
[Command Line Interface Guidelines](https://clig.dev/) baseline. The skill and
its reference guide remain the authoritative guidance; entries here identify
what was added beyond that baseline and why.

## Unreleased

### Added

- **Color control:** recommends `--color=always|auto|never` instead of a bare
  `--no-color` flag. Defines precedence among `NO_COLOR`, the `--color` flag,
  `TERM=dumb`, TTY detection, and `FORCE_COLOR`.
- **Additional environment variables:** checks `VISUAL` before `EDITOR` for
  multi-line input and supports `FORCE_COLOR` as the final color override.
- **Agent-friendly design:** recommends progressive machine-readable help,
  structured JSON errors, and informative output for human, scripted, and
  agent consumers.
- **POSIX sh portability:** adapts the guidance for portable shell scripts,
  including `getopts` limits, short options, ANSI color, and optional tools
  with plain fallbacks.
