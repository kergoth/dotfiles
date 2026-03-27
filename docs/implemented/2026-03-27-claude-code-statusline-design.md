# Claude Code Status Line Design

## Overview

A custom Claude Code status line that provides at-a-glance operational awareness, rate limit pacing, and context window usage. Styled to align with the existing vim statusline and tmux status bar design language (Dracula palette, dark background, selective color highlights, show-anomalies-only philosophy).

## Data Source

Claude Code's status line receives JSON via stdin containing session data. The script runs after each assistant message, debounced at 300ms. All data used in this design is natively available — no external tools required.

Key JSON fields consumed:

- `model.display_name` — model name ("Opus", "Sonnet", "Haiku")
- `cwd` / `workspace.project_dir` — current and project directories
- `context_window.used_percentage` — context window usage
- `rate_limits.five_hour.used_percentage` / `resets_at` — 5-hour rate limit window
- `rate_limits.seven_day.used_percentage` / `resets_at` — 7-day rate limit window
- `context_window.total_input_tokens` / `total_output_tokens` — for pace calculation
- `cost.total_duration_ms` — session elapsed time
- `worktree.name` / `worktree.branch` — worktree context
- `session_id` — session identifier
- `transcript_path` — path to conversation transcript

## Layout

### Conditional Name Line (Line 1, above operational bar)

Appears only when both conditions are met:

1. Session has been explicitly named via `/rename`
2. Terminal height >= 15 rows (`$LINES` or `tput lines`)

Format: `⌘ <session name>`

- Full terminal width, no truncation needed
- Slightly lighter background (`#313244`) than the operational bar to visually separate
- Dimmed icon, bright text
- Immune to degradation (lives on its own row)

### Operational Bar (main line, always present)

```
<model> <path> <branch>              <tasks> <rate limits> <context>
|------ left side ------|  spacer   |----------- right side ---------|
```

#### Left Side Segments (low → high degradation priority)

| Priority | Segment | Source | Style | Notes |
|----------|---------|--------|-------|-------|
| 1 (keep) | Model name | `model.display_name` | Bold, bright text, accent bg (`#45475a`) | Always shown |
| 2 | Project path | `cwd` / `workspace.project_dir` | Purple text | Fish-style shortened (see below) |
| 2 (alt) | Worktree | `worktree.name` | Cyan text, `⊕` prefix | Shown instead of path when in worktree |
| 3 | Branch | `worktree.branch` from JSON, else `git rev-parse --abbrev-ref HEAD` | Dim text | Prefer the zero-cost JSON field; fall back to git subprocess; omit if not in a git repo |

#### Right Side Segments (low → high degradation priority)

| Priority | Segment | Condition | Style | Notes |
|----------|---------|-----------|-------|-------|
| 1 (keep) | Context % | Always | Background color by severity | Always shown, last to degrade |
| 2 | Worst-state rate limit | >= 50% used | Background color + pace indicator | Whichever of 5h/7d is in worse shape |
| 3 (first to drop) | Second rate limit | >= 50% used | Background color + pace indicator | Drops before worst-state limit |

## Path Shortening

Uses fish shell-style unique prefix shortening for intermediate path segments:

- Each intermediate directory is shortened to the **shortest prefix that is unique among its siblings** in the filesystem
- The basename (final segment) is **never shortened**
- Paths under `$HOME` omit the `~/` prefix (e.g., `.dotfiles` not `~/.dotfiles`)
- Paths outside `$HOME` show the full absolute path
- Example: `~/Workspace/pano-ops/pano-ec` with sibling `pano-platform` → `W/pano-o/pano-ec`

Implementation notes:

- Cache the shortened path; only recompute when `cwd` changes
- Scan only sibling directories at each level for uniqueness

## Rate Limit Display

### Threshold Behavior

- **Below 50%**: hidden entirely (clean bar)
- **At or above 50%**: appears with pace indicator

### Pace Calculation

For each rate limit window, compute whether current usage pace will exhaust the limit before the window resets:

```
elapsed = now - (resets_at - window_duration)
pace = used_percentage / elapsed
projected_at_reset = pace * window_duration
over_pace = projected_at_reset > 100
time_to_exhaustion = (100 - used_percentage) / pace
```

Where `window_duration` is 5 hours or 7 days respectively.

### Display Format

| State | Format | Example |
|-------|--------|---------|
| On-track (will reset before exhaustion) | `Wh ✓ N%` | `5h ✓ 55%` |
| Over-pace (will exhaust before reset) | `Wh ⚠ N% ~T` | `5h ⚠ 62% ~1.2h` |

Where `W` = window label, `N` = percentage, `T` = time-to-exhaustion.

Time format: `~Xm` for minutes, `~X.Xh` for hours, `~X.Xd` for days.

### Smart Degradation

When terminal width requires dropping one rate limit window, keep whichever is in worse state:

```
if 7d_severity > 5h_severity → drop 5h, keep 7d
else → drop 7d, keep 5h
```

Severity ordering: critical (>= 90%) > over-pace warning > on-track > hidden.

## Color System

### Color Mode

Uses ANSI 24-bit truecolor (`\033[38;2;R;G;Bm` / `\033[48;2;R;G;Bm`). No 256-color fallback in the initial implementation, but all color values are defined as constants at the top of the script to support a future fallback path cleanly.

### Background Color Treatment

Uses **strong inverted backgrounds** (solid color bg, dark text) for percentage-based segments. This provides:

- High visibility at a glance without needing to parse text color
- Accessibility for red/green color vision deficiency (background fills are distinguishable by brightness/hue, not just foreground text tint)
- Visual consistency with vim's `cterm=reverse` statusline highlight groups

### Severity Thresholds and Colors

Rate limits and context % use different color strategies:

- **Rate limits** use solid inverted backgrounds whenever visible (they're hidden below 50%, so they're always prominent when shown)
- **Context %** uses subtle tinted background when healthy, escalating to solid inverted at warning/critical

#### Rate Limit Colors (only shown when >= 50%)

| State | Threshold | Background | Text |
|-------|-----------|------------|------|
| On-track | >= 50%, will reset before exhaustion | `#a6e3a1` (green) | `#1e1e2e` (dark) |
| Over-pace | >= 50%, will exhaust before reset | `#f9e2af` (yellow) | `#1e1e2e` (dark) |
| Critical | >= 80% | `#f38ba8` (red) | `#1e1e2e` (dark) |

#### Context Colors (always shown)

| State | Threshold | Background | Text |
|-------|-----------|------------|------|
| Good | < 50% | `#2a3a2a` (subtle green tint) | `#a6e3a1` (green) |
| Warning | >= 50% | `#f9e2af` (solid yellow) | `#1e1e2e` (dark) |
| Critical | >= 80% | `#f38ba8` (solid red) | `#1e1e2e` (dark) |

### Other Segment Colors

| Segment | Color | Code |
|---------|-------|------|
| Model name | Bright white, bold | `#cdd6f4` on `#45475a` |
| Project path | Purple | `#cba6f7` |
| Worktree name | Cyan with ⊕ prefix | `#94e2d5` |
| Branch | Dim | `#6c7086` |
| Session name icon | Dim | `#6c7086` |
| Session name text | Bright | `#cdd6f4` |
| Name line background | — | `#313244` |
| Main bar background | — | `#1e1e2e` |

## Degradation Tiers

When terminal width is insufficient for all segments, drop in this order:

| Tier | Action | Remaining |
|------|--------|-----------|
| 0 (full) | All segments shown | model, path, branch, rate limits, context |
| 1 | Drop lesser-severity rate limit | model, path, branch, worst rate limit, context |
| 2 | Drop project path | model, branch, worst rate limit, context |
| 3 | Drop branch | model, worst rate limit, context |
| 4 (minimum) | Drop rate limit | model, context |

Width detection: compare rendered character count (excluding ANSI escapes) against `$COLUMNS` (or `tput cols`).

## Constants

Configurable values at the top of the script for easy tuning:

```bash
# Thresholds
RATE_LIMIT_SHOW_THRESHOLD=50    # % at which rate limits appear
RATE_LIMIT_WARN_THRESHOLD=50    # % for yellow background
RATE_LIMIT_CRIT_THRESHOLD=80    # % for red background
CONTEXT_WARN_THRESHOLD=50       # % for yellow context background
CONTEXT_CRIT_THRESHOLD=80       # % for red context background
MIN_ROWS_FOR_NAME_LINE=15       # terminal height to show name line

# Symbols (redefine for ASCII-only terminals)
SYMBOL_ON_TRACK="✓"
SYMBOL_WARNING="⚠"
SYMBOL_SESSION="⌘"
SYMBOL_WORKTREE="⊕"

# Colors (ANSI 24-bit / Dracula-inspired)
# Defined as constants for easy theme swapping
```

## File Location

The script lives in the chezmoi source directory and is applied to the location referenced by `settings.json`:

- **Source:** `home/dot_claude/statusline-command.sh` (chezmoi-managed)
- **Target:** `~/.claude/statusline-command.sh`
- **Settings reference:** `settings.json` already contains `"statusLine": {"type": "command", "command": "bash ~/.claude/statusline-command.sh"}`

The script is not a chezmoi template — it has no platform-conditional logic. It runs only where Claude Code is installed (macOS, Linux workstations).

## Language

**Shell (bash) + jq.** Rationale:

- Avoids Python startup overhead (~30ms) on a script that runs after every assistant message
- `jq` handles all JSON parsing natively and efficiently
- Path shortening logic is simple enough in shell (`ls` + prefix matching)
- ANSI escape output is natural in shell
- Consistent with the existing `statusline-command.sh` that `settings.json` already points to

## Testing

**Test framework:** [Cram](https://bitheap.org/cram/) — functional testing framework for command-line applications. Run via `uvx cram`. Tests are `.t` files that look like interactive shell sessions: commands prefixed with `  $ `, expected output on indented lines, supports `(re)` for regex and `(glob)` for glob matching.

**Test strategy:**

- **Unit tests for pure functions:** source the script's functions and call them with known inputs. Test path shortening, pace calculation, severity classification, time formatting, degradation tier selection.
- **Integration tests:** feed mock JSON fixtures through the full script via stdin, capture output, strip ANSI escapes, and assert on segment content and ordering.
- **Path shortening tests:** create temporary directory trees with known sibling structures, verify unique prefix calculation produces correct and tab-completable results.
- **Degradation tests:** simulate various `$COLUMNS` values and verify correct segments are dropped in priority order.
- **Profiling/benchmarking:** the implementation plan must include a profiling step that measures end-to-end execution time with realistic JSON input. If path shortening exceeds 10ms or total script time exceeds 50ms, implement filesystem caching (write shortened path to a temp file keyed by `cwd`, reuse on subsequent invocations until `cwd` changes).

## Implementation Notes

- Script receives JSON on stdin; use `jq` for parsing
- Path shortening: start without caching (direct filesystem scan per invocation). Add caching only if profiling shows it's needed (see Testing section).
- Rate limit pace calculation uses `resets_at` epoch and current time
- Session name detection: the status line JSON does not include the session name directly, but provides `transcript_path`. The transcript JSONL contains two relevant event types:
  - `{"type": "custom-title", "customTitle": "..."}` — written when the user runs `/rename`. This is the user-chosen name.
  - `{"type": "agent-name", "agentName": "..."}` — written for `--agent` invocations.
  - A `slug` field (e.g., `"slug": "wiggly-toasting-engelbart"`) is present on system entries in all sessions — this is the auto-generated default name, not worth displaying.
  - **Strategy:** grep `transcript_path` for the last `custom-title` entry and extract `customTitle`. Show the name line only when a `custom-title` exists. Cache the result per `session_id` to avoid re-scanning the transcript on every invocation — invalidate by checking if the transcript file's mtime has changed.
- ANSI escape sequences for colors; test incrementally per Claude Code docs recommendation
- Script should be idempotent and fast (target < 50ms execution)

## Deferred / Out of Scope

- **Task count:** The status line JSON does not expose active task count. No reliable external source identified. Revisit if Claude Code adds this to the JSON schema.
- **256-color fallback:** All colors are defined as constants for easy swapping, but no automatic detection or fallback in v1. Add if needed for non-truecolor terminals.
- **`settings.json` chezmoi management:** The statusLine entry already exists in the user's `settings.json`. Making `settings.json` chezmoi-managed is a separate effort.
- **Session cost / burn rate:** Dropped in favor of native rate limit data, which directly answers "will I get throttled?" without dollar-amount abstraction.
- **LOC changed, vim mode, output style, agent name:** Reviewed and excluded — either shown elsewhere in the UI, not used, or low value.

## Design Alignment

This design follows patterns established in the existing vim and tmux configurations:

- **Vim**: show anomalies only (encoding/format only when non-default), User highlight groups with reverse video for emphasis, left = context/identity, right = metadata
- **Tmux**: dark neutral background (`colour234`), accent color for active elements, session identity anchors left, date/host anchors right
- **Shared**: information density scales with importance, defaults are hidden, color signals severity
