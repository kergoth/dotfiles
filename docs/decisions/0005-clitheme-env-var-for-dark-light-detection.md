---
status: accepted
date: 2026-06-15
decision-makers: kergoth
---

# Use CLITHEME for terminal dark/light mode communication

## Context and Problem Statement

The Claude Code and Cursor statusline scripts hardcoded colors for dark terminal backgrounds. Adding light-theme support required a way to communicate the terminal's color scheme to statusline subprocesses (and eventually other tools like vim, bat, delta). The statusline runs in a pipe without a controlling terminal, so runtime escape-sequence detection (OSC 11, CSI 996) is unavailable from within the subprocess itself.

How should tools in this dotfiles repo learn whether the terminal background is dark or light?

## Considered Options

* `COLORFGBG` (legacy, set by some terminals)
* `TERM_BACKGROUND=dark|light` (new, mirrors vim's `&background`)
* `CLITHEME=dark|light|auto` (aspirational CC0 standard from wiki.tau.garden/cli-theme/)
* Per-tool env vars (`BAT_THEME_DARK`, `STATUSLINE_THEME`, etc.)

## Decision Outcome

Chosen option: `CLITHEME`, because it follows a published specification modeled after the successful NO_COLOR convention, supports an `auto` value for "detect it yourself," and positions us to benefit if broader adoption occurs. The spec is CC0-licensed and already recognized by at least one detection library (shell-term-background).

`TERM_BACKGROUND` was the runner-up; it's self-documenting and mirrors vim's naming. We chose `CLITHEME` over it because the standardization upside outweighs the minor readability advantage, and `TERM_BACKGROUND` risks confusion with actual background color values (hex, RGB) rather than the dark/light polarity.

`COLORFGBG` was rejected as unreliable: few terminals set it, it uses opaque color indices rather than `dark`/`light`, and it doesn't update when the theme changes.

Per-tool env vars were rejected to avoid proliferation. One variable drives all tools.

### Consequences

* Good: one detection point in shell wrapper functions (claude, agent) serves all downstream tools
* Good: OSC 11 fallback in the wrapper runs with tty access; subprocess statuslines just read the variable
* Good: `auto` value lets tools that do have tty access perform their own detection
* Bad: zero mainstream tool adoption of `CLITHEME` yet; if a different convention wins, we rename
