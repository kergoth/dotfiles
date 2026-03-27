# Claude Code Status Line — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a custom Claude Code status line script that provides at-a-glance model identity, project context, rate limit pacing, and context window usage — styled after the existing vim/tmux Dracula-inspired design language.

**Architecture:** A single bash script (`statusline-command.sh`) receives JSON on stdin from Claude Code, extracts fields with `jq`, computes rate limit pace and path shortening, renders ANSI-colored segments, and handles graceful width-based degradation. Functions are structured for testability: pure functions for data transformation, a composition layer for assembly, and output rendering separated from logic.

**Tech Stack:** Bash, jq, git, [cram](https://bitheap.org/cram/) test framework (via `uvx cram`)

**Spec:** `docs/specs/2026-03-27-claude-code-statusline-design.md`

---

## File Structure

| File | Responsibility |
|------|---------------|
| `home/dot_claude/statusline-command.sh` | Main status line script (chezmoi source → `~/.claude/statusline-command.sh`) |
| `test/statusline/helpers.sh` | Shared test helpers: ANSI stripping, JSON fixture builders, temp directory setup |
| `test/statusline/colors.t` | Cram tests: ANSI color rendering, severity-to-color mapping |
| `test/statusline/context.t` | Cram tests: context % display, threshold color transitions |
| `test/statusline/rate-limits.t` | Cram tests: pace calculation, threshold visibility, display format, smart degradation |
| `test/statusline/path-shortening.t` | Cram tests: fish-style unique prefix, basename preservation, home-relative paths |
| `test/statusline/session-name.t` | Cram tests: custom-title extraction from transcript JSONL |
| `test/statusline/degradation.t` | Cram tests: width-based segment dropping at each tier |
| `test/statusline/integration.t` | Cram tests: full end-to-end with realistic JSON, multiple scenarios |
| `test/statusline/benchmark.t` | Cram test: profiling/benchmarking, timing assertions |

---

## Task 1: Script Skeleton + Color Constants

**Files:**
- Create: `home/dot_claude/statusline-command.sh`
- Create: `test/statusline/helpers.sh`
- Create: `test/statusline/colors.t`

- [ ] **Step 1: Write the color constant test**

Create `test/statusline/helpers.sh`:

```bash
#!/usr/bin/env bash
# Shared test helpers for statusline tests

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
STATUSLINE="$SCRIPT_DIR/home/dot_claude/statusline-command.sh"

# Source just the functions from the statusline script (skip main execution)
source_functions() {
    # The script guards main execution behind a "not sourced" check
    source "$STATUSLINE"
}

# Strip ANSI escape sequences from input
strip_ansi() {
    sed 's/\x1b\[[0-9;]*m//g' | sed 's/\x1b\[38;2;[0-9;]*m//g' | sed 's/\x1b\[48;2;[0-9;]*m//g'
}

# Build minimal JSON fixture (pass overrides as jq args)
# Usage: make_json '.model.display_name = "Opus" | .context_window.used_percentage = 35'
make_json() {
    local overrides="${1:-}"
    cat <<'BASEJSON' | jq "${overrides:-.}"
{
  "model": {"id": "claude-opus-4-6", "display_name": "Opus"},
  "cwd": "/Users/testuser/projects/myapp",
  "workspace": {"project_dir": "/Users/testuser/projects/myapp", "current_dir": "/Users/testuser/projects/myapp"},
  "context_window": {
    "used_percentage": 35,
    "remaining_percentage": 65,
    "context_window_size": 200000,
    "total_input_tokens": 70000,
    "total_output_tokens": 5000,
    "current_usage": {"input_tokens": 1000, "output_tokens": 200, "cache_creation_input_tokens": 0, "cache_read_input_tokens": 0}
  },
  "session_id": "test-session-001",
  "transcript_path": "/tmp/test-transcript.jsonl",
  "cost": {"total_cost_usd": 0.5, "total_duration_ms": 60000, "total_api_duration_ms": 45000, "total_lines_added": 0, "total_lines_removed": 0},
  "version": "2.1.85"
}
BASEJSON
}
```

Create `test/statusline/colors.t`:

```
Test color constant definitions:

  $ . "$TESTDIR"/helpers.sh && source_functions

All color constants must be defined (non-empty):

  $ [ -n "$COLOR_GREEN_BG" ] && echo ok
  ok
  $ [ -n "$COLOR_YELLOW_BG" ] && echo ok
  ok
  $ [ -n "$COLOR_RED_BG" ] && echo ok
  ok
  $ [ -n "$COLOR_DARK_TEXT" ] && echo ok
  ok
  $ [ -n "$COLOR_SUBTLE_GREEN_BG" ] && echo ok
  ok
  $ [ -n "$COLOR_RESET" ] && echo ok
  ok

Severity-to-color mapping for context:

  $ context_color 30
  subtle_green
  $ context_color 49
  subtle_green
  $ context_color 50
  yellow
  $ context_color 79
  yellow
  $ context_color 80
  red
  $ context_color 100
  red
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `uvx cram test/statusline/colors.t`
Expected: FAIL — script does not exist yet

- [ ] **Step 3: Write the script skeleton with color constants**

Create `home/dot_claude/statusline-command.sh`:

```bash
#!/usr/bin/env bash
# Claude Code status line — Dracula-inspired with rate limit pacing
# Spec: docs/specs/2026-03-27-claude-code-statusline-design.md

set -euo pipefail

# ── Thresholds ──────────────────────────────────────────────
RATE_LIMIT_SHOW_THRESHOLD=50
RATE_LIMIT_CRIT_THRESHOLD=80
CONTEXT_WARN_THRESHOLD=50
CONTEXT_CRIT_THRESHOLD=80
MIN_ROWS_FOR_NAME_LINE=15

# ── Symbols ─────────────────────────────────────────────────
SYMBOL_ON_TRACK="✓"
SYMBOL_WARNING="⚠"
SYMBOL_SESSION="⌘"
SYMBOL_WORKTREE="⊕"

# ── Colors (ANSI 24-bit truecolor) ─────────────────────────
# Backgrounds
COLOR_GREEN_BG=$'\033[48;2;166;227;161m'       # #a6e3a1
COLOR_YELLOW_BG=$'\033[48;2;249;226;175m'      # #f9e2af
COLOR_RED_BG=$'\033[48;2;243;139;168m'         # #f38ba8
COLOR_SUBTLE_GREEN_BG=$'\033[48;2;42;58;42m'   # #2a3a2a
COLOR_ACCENT_BG=$'\033[48;2;69;71;90m'         # #45475a
COLOR_NAME_LINE_BG=$'\033[48;2;49;50;68m'      # #313244

# Foregrounds
COLOR_DARK_TEXT=$'\033[38;2;30;30;46m'         # #1e1e2e
COLOR_BRIGHT_TEXT=$'\033[38;2;205;214;244m'    # #cdd6f4
COLOR_DIM_TEXT=$'\033[38;2;108;112;134m'       # #6c7086
COLOR_PURPLE_TEXT=$'\033[38;2;203;166;247m'    # #cba6f7
COLOR_CYAN_TEXT=$'\033[38;2;148;226;213m'      # #94e2d5
COLOR_GREEN_TEXT=$'\033[38;2;166;227;161m'     # #a6e3a1

COLOR_BOLD=$'\033[1m'
COLOR_RESET=$'\033[0m'

# ── Severity helpers ────────────────────────────────────────

# Returns severity name for context percentage
# Args: $1 = percentage (integer)
context_color() {
    local pct="${1:-0}"
    if (( pct >= CONTEXT_CRIT_THRESHOLD )); then
        echo "red"
    elif (( pct >= CONTEXT_WARN_THRESHOLD )); then
        echo "yellow"
    else
        echo "subtle_green"
    fi
}

# Returns severity name for rate limit percentage
# Args: $1 = percentage (integer)
rate_limit_color() {
    local pct="${1:-0}"
    if (( pct >= RATE_LIMIT_CRIT_THRESHOLD )); then
        echo "red"
    elif (( pct >= RATE_LIMIT_SHOW_THRESHOLD )); then
        echo "yellow"
    else
        echo "green"
    fi
}

# ── Main (only when not sourced) ────────────────────────────
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Read JSON from stdin
    input=$(cat)
    # TODO: implement in subsequent tasks
    echo "statusline placeholder"
fi
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `uvx cram test/statusline/colors.t`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add home/dot_claude/statusline-command.sh test/statusline/helpers.sh test/statusline/colors.t
git commit -m "Add statusline script skeleton with color constants and severity helpers"
```

---

## Task 2: Context % Segment

**Files:**
- Modify: `home/dot_claude/statusline-command.sh`
- Create: `test/statusline/context.t`

- [ ] **Step 1: Write the context display test**

Create `test/statusline/context.t`:

```
Test context percentage display:

  $ . "$TESTDIR"/helpers.sh && source_functions

Format context segment (returns raw text, caller wraps in color):

  $ format_context 35
  ctx 35%
  $ format_context 0
  ctx 0%
  $ format_context 100
  ctx 100%

Render context segment with correct color class:

  $ render_context_segment 35 | strip_ansi
  ctx 35%
  $ render_context_segment 72 | strip_ansi
  ctx 72%
  $ render_context_segment 92 | strip_ansi
  ctx 92%

Integration — pipe JSON through script, check context appears:

  $ . "$TESTDIR"/helpers.sh
  $ make_json '.context_window.used_percentage = 35' | bash "$STATUSLINE" | strip_ansi
  * ctx 35%* (glob)

Context at warning threshold:

  $ make_json '.context_window.used_percentage = 50' | bash "$STATUSLINE" | strip_ansi
  * ctx 50%* (glob)

Context at critical threshold:

  $ make_json '.context_window.used_percentage = 80' | bash "$STATUSLINE" | strip_ansi
  * ctx 80%* (glob)

No API calls yet (used_percentage is null):

  $ make_json 'del(.context_window.used_percentage)' | bash "$STATUSLINE" | strip_ansi
  * ctx 0%* (glob)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `uvx cram test/statusline/context.t`
Expected: FAIL — functions not yet implemented

- [ ] **Step 3: Implement context formatting and rendering**

Add to `home/dot_claude/statusline-command.sh` after the severity helpers:

```bash
# ── Segment rendering ───────────────────────────────────────

# Apply color pair (bg + fg) to text
# Args: $1 = bg escape, $2 = fg escape, $3 = text
colored() {
    printf '%s%s %s %s' "$1" "$2" "$3" "$COLOR_RESET"
}

# Format context percentage text
# Args: $1 = percentage (integer)
format_context() {
    printf 'ctx %d%%' "${1:-0}"
}

# Render context segment with appropriate severity colors
# Args: $1 = percentage (integer)
render_context_segment() {
    local pct="${1:-0}"
    local severity
    severity=$(context_color "$pct")
    local text
    text=$(format_context "$pct")

    case "$severity" in
        subtle_green) colored "$COLOR_SUBTLE_GREEN_BG" "$COLOR_GREEN_TEXT" "$text" ;;
        yellow)       colored "$COLOR_YELLOW_BG" "$COLOR_DARK_TEXT" "$text" ;;
        red)          colored "$COLOR_RED_BG" "$COLOR_DARK_TEXT" "$text" ;;
    esac
}
```

Update the main block:

```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    input=$(cat)

    # Parse JSON fields
    model=$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"')
    context_pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

    # Render segments
    left="${COLOR_ACCENT_BG}${COLOR_BOLD}${COLOR_BRIGHT_TEXT} ${model} ${COLOR_RESET}"
    right=$(render_context_segment "$context_pct")

    printf '%s  %s' "$left" "$right"
fi
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `uvx cram test/statusline/context.t`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add home/dot_claude/statusline-command.sh test/statusline/context.t
git commit -m "Add context percentage segment with severity-based colors"
```

---

## Task 3: Path Shortening

**Files:**
- Modify: `home/dot_claude/statusline-command.sh`
- Create: `test/statusline/path-shortening.t`

- [ ] **Step 1: Write the path shortening test**

Create `test/statusline/path-shortening.t`:

```
Test fish-style unique prefix path shortening:

  $ . "$TESTDIR"/helpers.sh && source_functions

Set up temp directory tree:

  $ mkdir -p "$CRAMTMP/home/Workspace/pano-ops/pano-ec"
  $ mkdir -p "$CRAMTMP/home/Workspace/pano-platform/backend"
  $ mkdir -p "$CRAMTMP/home/Workspace/personal/dotfiles"
  $ mkdir -p "$CRAMTMP/home/.config/nvim"
  $ mkdir -p "$CRAMTMP/home/.claude/projects"
  $ mkdir -p "$CRAMTMP/home/.cargo/bin"
  $ mkdir -p "$CRAMTMP/outside/usr/local/bin"

Basename is never shortened:

  $ shorten_path "$CRAMTMP/home/Workspace/pano-ops/pano-ec" "$CRAMTMP/home"
  W/pano-o/pano-ec

Siblings with shared prefix get unique prefixes:

  $ shorten_path "$CRAMTMP/home/Workspace/pano-platform/backend" "$CRAMTMP/home"
  W/pano-p/backend

No ambiguity — single char is enough:

  $ shorten_path "$CRAMTMP/home/Workspace/personal/dotfiles" "$CRAMTMP/home"
  W/p/dotfiles

Dot-prefixed dirs work:

  $ shorten_path "$CRAMTMP/home/.config/nvim" "$CRAMTMP/home"
  .co/nvim

Multiple dot-prefixed siblings disambiguate:

  $ shorten_path "$CRAMTMP/home/.claude/projects" "$CRAMTMP/home"
  .cl/projects

  $ shorten_path "$CRAMTMP/home/.cargo/bin" "$CRAMTMP/home"
  .ca/bin

Path outside home shows full absolute path:

  $ shorten_path "$CRAMTMP/outside/usr/local/bin" "$CRAMTMP/home"
  $CRAMTMP/outside/usr/local/bin (no-eol)

Single segment under home:

  $ mkdir -p "$CRAMTMP/home/myproject"
  $ shorten_path "$CRAMTMP/home/myproject" "$CRAMTMP/home"
  myproject

Path is home itself:

  $ shorten_path "$CRAMTMP/home" "$CRAMTMP/home"
  ~
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `uvx cram test/statusline/path-shortening.t`
Expected: FAIL — `shorten_path` not defined

- [ ] **Step 3: Implement shorten_path**

Add to `home/dot_claude/statusline-command.sh` after the color constants:

```bash
# ── Path shortening (fish-style unique prefix) ─────────────

# Shorten path for display using unique prefix per intermediate segment.
# Basename is never shortened. Paths under $home omit the prefix.
# Args: $1 = full path, $2 = home directory (default: $HOME)
shorten_path() {
    local full_path="$1"
    local home="${2:-$HOME}"

    # Exact home match
    if [[ "$full_path" == "$home" ]]; then
        echo "~"
        return
    fi

    # Check if path is under home
    local relative=""
    if [[ "$full_path" == "$home"/* ]]; then
        relative="${full_path#"$home"/}"
    else
        # Outside home — return full absolute path
        printf '%s' "$full_path"
        return
    fi

    # Split into segments
    local IFS='/'
    read -ra segments <<< "$relative"

    local segment_count=${#segments[@]}
    if (( segment_count <= 1 )); then
        echo "$relative"
        return
    fi

    # Shorten each intermediate segment (all except last)
    local result=""
    local current_dir="$home"
    local i
    for (( i = 0; i < segment_count - 1; i++ )); do
        local seg="${segments[$i]}"
        current_dir="$current_dir/$seg"
        local parent="${current_dir%/"$seg"}"

        # Find shortest unique prefix among siblings
        local prefix
        prefix=$(unique_prefix "$seg" "$parent")
        result="${result:+$result/}$prefix"
    done

    # Append full basename
    echo "$result/${segments[$((segment_count - 1))]}"
}

# Find shortest unique prefix of $name among entries in $dir.
# Args: $1 = name, $2 = parent directory
unique_prefix() {
    local name="$1"
    local parent="$2"

    # List sibling directory names (excluding the target itself)
    local siblings=()
    local entry
    while IFS= read -r entry; do
        [[ "$entry" != "$name" ]] && siblings+=("$entry")
    done < <(ls -1 "$parent" 2>/dev/null)

    # Find shortest prefix that doesn't match any sibling
    local len
    for (( len = 1; len <= ${#name}; len++ )); do
        local prefix="${name:0:$len}"
        local collision=false
        local sib
        for sib in "${siblings[@]}"; do
            if [[ "$sib" == "$prefix"* ]]; then
                collision=true
                break
            fi
        done
        if ! $collision; then
            echo "$prefix"
            return
        fi
    done

    # Full name if no unique prefix found (shouldn't happen)
    echo "$name"
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `uvx cram test/statusline/path-shortening.t`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add home/dot_claude/statusline-command.sh test/statusline/path-shortening.t
git commit -m "Add fish-style unique prefix path shortening"
```

---

## Task 4: Rate Limit Pace Calculation

**Files:**
- Modify: `home/dot_claude/statusline-command.sh`
- Create: `test/statusline/rate-limits.t`

- [ ] **Step 1: Write the rate limit test**

Create `test/statusline/rate-limits.t`:

```
Test rate limit pace calculation and display:

  $ . "$TESTDIR"/helpers.sh && source_functions

Format time-to-exhaustion:

  $ format_time_remaining 900
  ~15m
  $ format_time_remaining 4320
  ~1.2h
  $ format_time_remaining 86400
  ~1.0d
  $ format_time_remaining 155520
  ~1.8d
  $ format_time_remaining 60
  ~1m
  $ format_time_remaining 7200
  ~2.0h

Rate limit visibility — below threshold returns empty:

  $ format_rate_limit "5h" 30 0 18000


Above threshold, on-track (won't exhaust before reset):

  $ format_rate_limit "5h" 55 12600 18000
  5h \xe2\x9c\x93 55% (esc)

Above threshold, over-pace (will exhaust before reset):

  $ format_rate_limit "5h" 62 7200 18000
  5h \xe2\x9a\xa0 62% ~1.2h (esc)

Critical (>= 80%), over-pace:

  $ format_rate_limit "5h" 89 14400 18000
  5h \xe2\x9a\xa0 89% ~15m (esc)

7-day window:

  $ format_rate_limit "7d" 52 259200 604800
  7d \xe2\x9c\x93 52% (esc)

Severity classification:

  $ rate_limit_severity 30 false
  hidden
  $ rate_limit_severity 55 false
  on_track
  $ rate_limit_severity 62 true
  over_pace
  $ rate_limit_severity 89 true
  critical

Smart degradation — keep worse state:

  $ worse_rate_limit "critical" "on_track"
  first
  $ worse_rate_limit "on_track" "over_pace"
  second
  $ worse_rate_limit "hidden" "on_track"
  second
  $ worse_rate_limit "on_track" "on_track"
  first
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `uvx cram test/statusline/rate-limits.t`
Expected: FAIL

- [ ] **Step 3: Implement rate limit functions**

Add to `home/dot_claude/statusline-command.sh`:

```bash
# ── Rate limit helpers ──────────────────────────────────────

# Format seconds into human-readable time
# Args: $1 = seconds
format_time_remaining() {
    local secs="$1"
    if (( secs < 3600 )); then
        printf '~%dm' $(( secs / 60 ))
    elif (( secs < 86400 )); then
        printf '~%.1fh' "$(echo "scale=1; $secs / 3600" | bc)"
    else
        printf '~%.1fd' "$(echo "scale=1; $secs / 86400" | bc)"
    fi
}

# Classify rate limit severity
# Args: $1 = percentage, $2 = is_over_pace (true/false)
rate_limit_severity() {
    local pct="$1"
    local over_pace="$2"
    if (( pct < RATE_LIMIT_SHOW_THRESHOLD )); then
        echo "hidden"
    elif (( pct >= RATE_LIMIT_CRIT_THRESHOLD )) && [[ "$over_pace" == "true" ]]; then
        echo "critical"
    elif [[ "$over_pace" == "true" ]]; then
        echo "over_pace"
    else
        echo "on_track"
    fi
}

# Determine which of two rate limits is in worse state
# Args: $1 = severity_a, $2 = severity_b
# Returns: "first" or "second"
worse_rate_limit() {
    local -A severity_rank=([hidden]=0 [on_track]=1 [over_pace]=2 [critical]=3)
    local rank_a="${severity_rank[$1]:-0}"
    local rank_b="${severity_rank[$2]:-0}"
    if (( rank_a >= rank_b )); then
        echo "first"
    else
        echo "second"
    fi
}

# Format rate limit segment text (without ANSI colors)
# Args: $1 = label ("5h"/"7d"), $2 = percentage, $3 = elapsed_secs, $4 = window_secs
format_rate_limit() {
    local label="$1"
    local pct="$2"
    local elapsed="$3"
    local window="$4"

    # Below threshold — return empty
    if (( pct < RATE_LIMIT_SHOW_THRESHOLD )); then
        return
    fi

    # Calculate pace
    local over_pace=false
    local time_to_exhaust=""
    if (( elapsed > 0 )); then
        # projected = (pct / elapsed) * window
        local projected
        projected=$(echo "scale=2; $pct * $window / $elapsed" | bc)
        local projected_int
        projected_int=$(printf '%.0f' "$projected")
        if (( projected_int > 100 )); then
            over_pace=true
            # time_to_exhaust = (100 - pct) / (pct / elapsed)
            local tte
            tte=$(echo "scale=0; (100 - $pct) * $elapsed / $pct" | bc)
            time_to_exhaust=$(format_time_remaining "$tte")
        fi
    fi

    if [[ "$over_pace" == "true" ]]; then
        printf '%s %s %d%% %s' "$label" "$SYMBOL_WARNING" "$pct" "$time_to_exhaust"
    else
        printf '%s %s %d%%' "$label" "$SYMBOL_ON_TRACK" "$pct"
    fi
}

# Render rate limit segment with ANSI colors
# Args: $1 = label, $2 = percentage, $3 = elapsed_secs, $4 = window_secs
render_rate_limit_segment() {
    local text
    text=$(format_rate_limit "$@")
    [[ -z "$text" ]] && return

    local label="$1" pct="$2" elapsed="$3" window="$4"

    # Determine over_pace for severity
    local over_pace=false
    if (( elapsed > 0 && pct >= RATE_LIMIT_SHOW_THRESHOLD )); then
        local projected
        projected=$(echo "scale=2; $pct * $window / $elapsed" | bc)
        local projected_int
        projected_int=$(printf '%.0f' "$projected")
        (( projected_int > 100 )) && over_pace=true
    fi

    local severity
    severity=$(rate_limit_severity "$pct" "$over_pace")

    case "$severity" in
        on_track) colored "$COLOR_GREEN_BG" "$COLOR_DARK_TEXT" "$text" ;;
        over_pace) colored "$COLOR_YELLOW_BG" "$COLOR_DARK_TEXT" "$text" ;;
        critical) colored "$COLOR_RED_BG" "$COLOR_DARK_TEXT" "$text" ;;
    esac
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `uvx cram test/statusline/rate-limits.t`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add home/dot_claude/statusline-command.sh test/statusline/rate-limits.t
git commit -m "Add rate limit pace calculation with smart degradation"
```

---

## Task 5: Session Name Detection

**Files:**
- Modify: `home/dot_claude/statusline-command.sh`
- Create: `test/statusline/session-name.t`

- [ ] **Step 1: Write the session name test**

Create `test/statusline/session-name.t`:

```
Test session name extraction from transcript JSONL:

  $ . "$TESTDIR"/helpers.sh && source_functions

Create transcript with custom-title:

  $ cat > "$CRAMTMP/renamed.jsonl" << 'EOF'
  > {"type":"user","sessionId":"abc-123","content":"hello"}
  > {"type":"assistant","sessionId":"abc-123","content":"hi"}
  > {"type":"custom-title","customTitle":"my cool project","sessionId":"abc-123"}
  > {"type":"user","sessionId":"abc-123","content":"more work"}
  > EOF

  $ get_session_name "$CRAMTMP/renamed.jsonl"
  my cool project

Transcript without custom-title returns empty:

  $ cat > "$CRAMTMP/unnamed.jsonl" << 'EOF'
  > {"type":"user","sessionId":"def-456","content":"hello"}
  > {"type":"assistant","sessionId":"def-456","content":"hi"}
  > EOF

  $ get_session_name "$CRAMTMP/unnamed.jsonl"


Multiple renames — use last one:

  $ cat > "$CRAMTMP/multi-rename.jsonl" << 'EOF'
  > {"type":"custom-title","customTitle":"first name","sessionId":"ghi-789"}
  > {"type":"user","sessionId":"ghi-789","content":"work"}
  > {"type":"custom-title","customTitle":"better name","sessionId":"ghi-789"}
  > EOF

  $ get_session_name "$CRAMTMP/multi-rename.jsonl"
  better name

Non-existent transcript returns empty:

  $ get_session_name "$CRAMTMP/no-such-file.jsonl"


Name line rendering (with sufficient terminal height):

  $ LINES=20 render_name_line "my cool project" | strip_ansi
  \xe2\x8c\x98 my cool project (esc)

Name line suppressed when terminal too short:

  $ LINES=10 render_name_line "my cool project"

```

- [ ] **Step 2: Run tests to verify they fail**

Run: `uvx cram test/statusline/session-name.t`
Expected: FAIL

- [ ] **Step 3: Implement session name functions**

Add to `home/dot_claude/statusline-command.sh`:

```bash
# ── Session name ────────────────────────────────────────────

# Extract custom session name from transcript JSONL
# Args: $1 = transcript_path
get_session_name() {
    local transcript="$1"
    [[ -f "$transcript" ]] || return

    # Find the last custom-title entry, extract customTitle
    grep '"type":"custom-title"' "$transcript" 2>/dev/null \
        | tail -1 \
        | jq -r '.customTitle // empty' 2>/dev/null
}

# Render the conditional name line (above operational bar)
# Args: $1 = session name (empty = no line)
render_name_line() {
    local name="$1"
    [[ -z "$name" ]] && return

    local rows="${LINES:-$(tput lines 2>/dev/null || echo 24)}"
    (( rows < MIN_ROWS_FOR_NAME_LINE )) && return

    printf '%s%s %s %s %s\n' \
        "$COLOR_NAME_LINE_BG" \
        "$COLOR_DIM_TEXT" "$SYMBOL_SESSION" \
        "${COLOR_BRIGHT_TEXT}${name}" \
        "$COLOR_RESET"
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `uvx cram test/statusline/session-name.t`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add home/dot_claude/statusline-command.sh test/statusline/session-name.t
git commit -m "Add session name detection from transcript JSONL"
```

---

## Task 6: Width-Based Degradation

**Files:**
- Modify: `home/dot_claude/statusline-command.sh`
- Create: `test/statusline/degradation.t`

- [ ] **Step 1: Write the degradation test**

Create `test/statusline/degradation.t`:

```
Test width-based degradation tiers:

  $ . "$TESTDIR"/helpers.sh && source_functions

Measure visible width of a string (strip ANSI, count characters):

  $ visible_width "hello"
  5
  $ printf '\033[38;2;166;227;161mhello\033[0m' | strip_ansi | wc -m | tr -d ' '
  5

Build all segments and test tier selection:

  $ select_degradation_tier 120 "Opus" "W/p-o/pano-ec" "main" "5h * 62% ~1.2h" "7d * 52%" "ctx 45%"
  0
  $ select_degradation_tier 80 "Opus" "W/p-o/pano-ec" "main" "5h * 62% ~1.2h" "7d * 52%" "ctx 45%"
  1
  $ select_degradation_tier 60 "Opus" "W/p-o/pano-ec" "main" "5h * 62% ~1.2h" "" "ctx 45%"
  2
  $ select_degradation_tier 40 "Opus" "" "main" "5h * 62% ~1.2h" "" "ctx 45%"
  3
  $ select_degradation_tier 25 "Opus" "" "" "5h * 62% ~1.2h" "" "ctx 45%"
  4

Visible width helper:

  $ visible_width "Opus  W/p-o/pano-ec  main  5h * 62% ~1.2h  7d * 52%  ctx 45%"
  63
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `uvx cram test/statusline/degradation.t`
Expected: FAIL

- [ ] **Step 3: Implement degradation logic**

Add to `home/dot_claude/statusline-command.sh`:

```bash
# ── Degradation ─────────────────────────────────────────────

# Count visible characters (strip ANSI escapes)
# Args: $1 = string
visible_width() {
    printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g; s/\x1b\[38;2;[0-9;]*m//g; s/\x1b\[48;2;[0-9;]*m//g' | wc -m | tr -d ' '
}

# Select degradation tier based on available width
# Args: $1 = columns, $2..N = segment texts (plain, for width measurement)
# Segments order: model, path, branch, rate_limit_worst, rate_limit_second, context
# Returns: tier number (0-4)
select_degradation_tier() {
    local cols="$1"
    local model="$2"
    local path="$3"
    local branch="$4"
    local rl_worst="$5"
    local rl_second="$6"
    local context="$7"

    local padding=6  # padding between segments + separators

    # Tier 0: all segments
    local total=0
    local seg
    for seg in "$model" "$path" "$branch" "$rl_worst" "$rl_second" "$context"; do
        [[ -n "$seg" ]] && total=$(( total + ${#seg} + 2 ))
    done
    total=$(( total + padding ))
    (( total <= cols )) && { echo 0; return; }

    # Tier 1: drop second rate limit
    total=0
    for seg in "$model" "$path" "$branch" "$rl_worst" "$context"; do
        [[ -n "$seg" ]] && total=$(( total + ${#seg} + 2 ))
    done
    total=$(( total + padding ))
    (( total <= cols )) && { echo 1; return; }

    # Tier 2: drop path
    total=0
    for seg in "$model" "$branch" "$rl_worst" "$context"; do
        [[ -n "$seg" ]] && total=$(( total + ${#seg} + 2 ))
    done
    total=$(( total + padding ))
    (( total <= cols )) && { echo 2; return; }

    # Tier 3: drop branch
    total=0
    for seg in "$model" "$rl_worst" "$context"; do
        [[ -n "$seg" ]] && total=$(( total + ${#seg} + 2 ))
    done
    total=$(( total + padding ))
    (( total <= cols )) && { echo 3; return; }

    # Tier 4: minimum (model + context)
    echo 4
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `uvx cram test/statusline/degradation.t`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add home/dot_claude/statusline-command.sh test/statusline/degradation.t
git commit -m "Add width-based degradation tier selection"
```

---

## Task 7: Main Composition — Assemble Full Output

**Files:**
- Modify: `home/dot_claude/statusline-command.sh`
- Create: `test/statusline/integration.t`

- [ ] **Step 1: Write the integration test**

Create `test/statusline/integration.t`:

```
Full integration — pipe realistic JSON, verify output:

  $ . "$TESTDIR"/helpers.sh

Calm session — model, path, branch, context only:

  $ HOME="$CRAMTMP/home" COLUMNS=120
  $ mkdir -p "$HOME/projects/myapp/.git"
  $ cd "$HOME/projects/myapp"
  $ git init -q
  $ make_json '.cwd = "'"$HOME/projects/myapp"'" | .workspace.project_dir = "'"$HOME/projects/myapp"'"' \
  >   | bash "$STATUSLINE" | strip_ansi
  * Opus *myapp*main* ctx 35%* (glob)

Rate limit at 55%, on-track:

  $ NOW=$(date +%s)
  $ RESET_5H=$(( NOW + 5400 ))
  $ make_json '
  >   .cwd = "'"$HOME/projects/myapp"'"
  >   | .workspace.project_dir = "'"$HOME/projects/myapp"'"
  >   | .rate_limits.five_hour.used_percentage = 55
  >   | .rate_limits.five_hour.resets_at = '"$RESET_5H"'
  > ' | bash "$STATUSLINE" | strip_ansi
  *5h*55%*ctx 35%* (glob)

Rate limit over-pace:

  $ RESET_5H=$(( NOW + 10800 ))
  $ make_json '
  >   .cwd = "'"$HOME/projects/myapp"'"
  >   | .workspace.project_dir = "'"$HOME/projects/myapp"'"
  >   | .rate_limits.five_hour.used_percentage = 62
  >   | .rate_limits.five_hour.resets_at = '"$RESET_5H"'
  > ' | bash "$STATUSLINE" | strip_ansi
  *5h*62%*~*ctx 35%* (glob)

Narrow terminal — segments degrade:

  $ COLUMNS=40 make_json '.cwd = "'"$HOME/projects/myapp"'" | .workspace.project_dir = "'"$HOME/projects/myapp"'"' \
  >   | bash "$STATUSLINE" | strip_ansi
  * Opus * ctx 35%* (glob)

Worktree session:

  $ make_json '
  >   .worktree.name = "upload-retry"
  >   | .worktree.branch = "feature/retry-logic"
  >   | .worktree.path = "/tmp/worktree"
  >   | .cwd = "/tmp/worktree"
  >   | .workspace.project_dir = "/tmp/worktree"
  > ' | COLUMNS=120 bash "$STATUSLINE" | strip_ansi
  *upload-retry*retry-logic*ctx 35%* (glob)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `uvx cram test/statusline/integration.t`
Expected: FAIL — main block is placeholder

- [ ] **Step 3: Implement full composition in main block**

Replace the main block in `home/dot_claude/statusline-command.sh`:

```bash
# ── Main (only when not sourced) ────────────────────────────
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    input=$(cat)
    cols="${COLUMNS:-$(tput cols 2>/dev/null || echo 120)}"

    # ── Parse JSON ──────────────────────────────────────────
    model=$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"')
    context_pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
    cwd=$(printf '%s' "$input" | jq -r '.cwd // ""')
    transcript=$(printf '%s' "$input" | jq -r '.transcript_path // ""')
    session_id=$(printf '%s' "$input" | jq -r '.session_id // ""')

    # Worktree fields
    wt_name=$(printf '%s' "$input" | jq -r '.worktree.name // empty' 2>/dev/null)
    wt_branch=$(printf '%s' "$input" | jq -r '.worktree.branch // empty' 2>/dev/null)

    # Rate limits
    rl_5h_pct=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // 0' | cut -d. -f1)
    rl_5h_resets=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at // 0' | cut -d. -f1)
    rl_7d_pct=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // 0' | cut -d. -f1)
    rl_7d_resets=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.resets_at // 0' | cut -d. -f1)

    # ── Compute derived values ──────────────────────────────
    now=$(date +%s)

    # Branch: prefer worktree.branch, fall back to git
    if [[ -n "$wt_branch" ]]; then
        branch="$wt_branch"
    elif [[ -n "$cwd" ]] && git -C "$cwd" rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
        branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
    else
        branch=""
    fi

    # Path: worktree name or shortened project path
    if [[ -n "$wt_name" ]]; then
        display_path="${SYMBOL_WORKTREE} ${wt_name}"
    elif [[ -n "$cwd" ]]; then
        display_path=$(shorten_path "$cwd" "$HOME")
    else
        display_path=""
    fi

    # Rate limit elapsed times
    rl_5h_elapsed=0
    if (( rl_5h_resets > 0 )); then
        rl_5h_elapsed=$(( 18000 - (rl_5h_resets - now) ))
        (( rl_5h_elapsed < 0 )) && rl_5h_elapsed=0
    fi
    rl_7d_elapsed=0
    if (( rl_7d_resets > 0 )); then
        rl_7d_elapsed=$(( 604800 - (rl_7d_resets - now) ))
        (( rl_7d_elapsed < 0 )) && rl_7d_elapsed=0
    fi

    # Rate limit text (plain, for width measurement)
    rl_5h_text=$(format_rate_limit "5h" "$rl_5h_pct" "$rl_5h_elapsed" 18000)
    rl_7d_text=$(format_rate_limit "7d" "$rl_7d_pct" "$rl_7d_elapsed" 604800)
    context_text=$(format_context "$context_pct")

    # ── Smart rate limit ordering ───────────────────────────
    # Determine severity for smart degradation
    rl_5h_over_pace=false
    if (( rl_5h_elapsed > 0 && rl_5h_pct >= RATE_LIMIT_SHOW_THRESHOLD )); then
        local proj
        proj=$(echo "scale=2; $rl_5h_pct * 18000 / $rl_5h_elapsed" | bc)
        (( $(printf '%.0f' "$proj") > 100 )) && rl_5h_over_pace=true
    fi
    rl_7d_over_pace=false
    if (( rl_7d_elapsed > 0 && rl_7d_pct >= RATE_LIMIT_SHOW_THRESHOLD )); then
        local proj
        proj=$(echo "scale=2; $rl_7d_pct * 604800 / $rl_7d_elapsed" | bc)
        (( $(printf '%.0f' "$proj") > 100 )) && rl_7d_over_pace=true
    fi

    sev_5h=$(rate_limit_severity "$rl_5h_pct" "$rl_5h_over_pace")
    sev_7d=$(rate_limit_severity "$rl_7d_pct" "$rl_7d_over_pace")

    worse=$(worse_rate_limit "$sev_5h" "$sev_7d")
    if [[ "$worse" == "first" ]]; then
        rl_worst_text="$rl_5h_text"
        rl_worst_args=("5h" "$rl_5h_pct" "$rl_5h_elapsed" 18000)
        rl_second_text="$rl_7d_text"
        rl_second_args=("7d" "$rl_7d_pct" "$rl_7d_elapsed" 604800)
    else
        rl_worst_text="$rl_7d_text"
        rl_worst_args=("7d" "$rl_7d_pct" "$rl_7d_elapsed" 604800)
        rl_second_text="$rl_5h_text"
        rl_second_args=("5h" "$rl_5h_pct" "$rl_5h_elapsed" 18000)
    fi

    # ── Degradation ─────────────────────────────────────────
    tier=$(select_degradation_tier "$cols" "$model" "$display_path" "$branch" "$rl_worst_text" "$rl_second_text" "$context_text")

    # ── Session name (conditional line above) ───────────────
    session_name=""
    if [[ -n "$transcript" ]]; then
        session_name=$(get_session_name "$transcript")
    fi
    if [[ -n "$session_name" ]]; then
        render_name_line "$session_name"
    fi

    # ── Render operational bar ──────────────────────────────
    # Left side
    printf '%s%s%s %s %s' "$COLOR_ACCENT_BG" "$COLOR_BOLD" "$COLOR_BRIGHT_TEXT" "$model" "$COLOR_RESET"

    if (( tier <= 1 )) && [[ -n "$display_path" ]]; then
        if [[ -n "$wt_name" ]]; then
            printf ' %s%s%s' "$COLOR_CYAN_TEXT" "$display_path" "$COLOR_RESET"
        else
            printf ' %s%s%s' "$COLOR_PURPLE_TEXT" "$display_path" "$COLOR_RESET"
        fi
    fi

    if (( tier <= 2 )) && [[ -n "$branch" ]]; then
        printf ' %s%s%s' "$COLOR_DIM_TEXT" "$branch" "$COLOR_RESET"
    fi

    # Right side (separated by spaces — printf handles alignment)
    printf '  '

    if (( tier <= 0 )) && [[ -n "$rl_second_text" ]]; then
        render_rate_limit_segment "${rl_second_args[@]}"
        printf ' '
    fi

    if (( tier <= 3 )) && [[ -n "$rl_worst_text" ]]; then
        render_rate_limit_segment "${rl_worst_args[@]}"
        printf ' '
    fi

    render_context_segment "$context_pct"
fi
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `uvx cram test/statusline/integration.t`
Expected: PASS

- [ ] **Step 5: Run all tests**

Run: `uvx cram test/statusline/`
Expected: all PASS

- [ ] **Step 6: Commit**

```bash
git add home/dot_claude/statusline-command.sh test/statusline/integration.t
git commit -m "Assemble full status line with all segments and degradation"
```

---

## Task 8: Profiling and Benchmarking

**Files:**
- Create: `test/statusline/benchmark.t`

- [ ] **Step 1: Write the benchmark test**

Create `test/statusline/benchmark.t`:

```
Profile status line execution time:

  $ . "$TESTDIR"/helpers.sh

Set up a realistic directory tree for path shortening:

  $ mkdir -p "$CRAMTMP/home/Workspace/pano-ops/pano-ec/.git"
  $ mkdir -p "$CRAMTMP/home/Workspace/pano-platform"
  $ mkdir -p "$CRAMTMP/home/Workspace/personal"
  $ cd "$CRAMTMP/home/Workspace/pano-ops/pano-ec"
  $ git init -q

Build realistic JSON with all fields populated:

  $ NOW=$(date +%s)
  $ RESET_5H=$(( NOW + 10800 ))
  $ RESET_7D=$(( NOW + 432000 ))
  $ JSON=$(HOME="$CRAMTMP/home" make_json '
  >   .cwd = "'"$CRAMTMP/home/Workspace/pano-ops/pano-ec"'"
  >   | .workspace.project_dir = "'"$CRAMTMP/home/Workspace/pano-ops/pano-ec"'"
  >   | .context_window.used_percentage = 45
  >   | .rate_limits.five_hour.used_percentage = 62
  >   | .rate_limits.five_hour.resets_at = '"$RESET_5H"'
  >   | .rate_limits.seven_day.used_percentage = 35
  >   | .rate_limits.seven_day.resets_at = '"$RESET_7D"'
  > ')

Warm up (first run may be slower due to shell/jq startup):

  $ echo "$JSON" | HOME="$CRAMTMP/home" COLUMNS=120 bash "$STATUSLINE" > /dev/null

Measure 5 runs and report average:

  $ total=0
  > for i in 1 2 3 4 5; do
  >   start=$(python3 -c 'import time; print(int(time.time()*1000))')
  >   echo "$JSON" | HOME="$CRAMTMP/home" COLUMNS=120 bash "$STATUSLINE" > /dev/null
  >   end=$(python3 -c 'import time; print(int(time.time()*1000))')
  >   elapsed=$(( end - start ))
  >   total=$(( total + elapsed ))
  > done
  > avg=$(( total / 5 ))
  > echo "Average: ${avg}ms"
  > if [ "$avg" -le 50 ]; then
  >   echo "PASS: under 50ms target"
  > else
  >   echo "WARN: ${avg}ms exceeds 50ms target — consider adding path cache"
  > fi
  Average: *ms (glob)
  PASS: under 50ms target (glob)
```

- [ ] **Step 2: Run the benchmark**

Run: `uvx cram test/statusline/benchmark.t`
Expected: PASS with timing under 50ms. If timing exceeds 50ms, proceed to Step 3. Otherwise skip to Step 4.

- [ ] **Step 3: (Conditional) Implement path shortening cache**

Only if benchmark shows > 50ms. Add to `home/dot_claude/statusline-command.sh`:

```bash
# Cache file for shortened paths
_PATH_CACHE_DIR="${TMPDIR:-/tmp}/claude-statusline-cache"

# Cached shorten_path — checks if cwd matches cached value
cached_shorten_path() {
    local full_path="$1"
    local home="${2:-$HOME}"
    local cache_file="$_PATH_CACHE_DIR/path"

    mkdir -p "$_PATH_CACHE_DIR" 2>/dev/null

    if [[ -f "$cache_file" ]]; then
        local cached_input cached_output
        cached_input=$(head -1 "$cache_file")
        if [[ "$cached_input" == "$full_path" ]]; then
            cached_output=$(tail -1 "$cache_file")
            echo "$cached_output"
            return
        fi
    fi

    local result
    result=$(shorten_path "$full_path" "$home")
    printf '%s\n%s\n' "$full_path" "$result" > "$cache_file"
    echo "$result"
}
```

Then replace `shorten_path` call in main with `cached_shorten_path`.

- [ ] **Step 4: Commit**

```bash
git add test/statusline/benchmark.t
git commit -m "Add profiling benchmark for status line execution time"
```

If caching was added:

```bash
git add home/dot_claude/statusline-command.sh test/statusline/benchmark.t
git commit -m "Add path shortening cache to meet 50ms target"
```

---

## Task 9: Deploy and Apply via Chezmoi

**Files:**
- Modify: `home/dot_claude/statusline-command.sh` (ensure executable bit)

- [ ] **Step 1: Verify the script is marked executable in chezmoi**

```bash
ls -la home/dot_claude/statusline-command.sh
```

If not executable:

```bash
chmod +x home/dot_claude/statusline-command.sh
```

Chezmoi uses the `executable_` prefix for scripts that need the execute bit. Since `settings.json` invokes it as `bash ~/.claude/statusline-command.sh`, the execute bit isn't strictly required, but set it for consistency.

- [ ] **Step 2: Check chezmoi would apply it correctly**

```bash
chezmoi diff
```

Expected: shows the new `statusline-command.sh` being created or updated at `~/.claude/statusline-command.sh`.

- [ ] **Step 3: Apply via chezmoi**

```bash
chezmoi apply ~/.claude/statusline-command.sh
```

- [ ] **Step 4: Verify the applied script works**

Open a new Claude Code session (or use the current one). The status line should render with the new format. Verify:

1. Model name appears on the left with accent background
2. Project path is shortened correctly
3. Branch is shown
4. Context % appears with appropriate color
5. If rate limits are above 50%, they appear with pace indicators

- [ ] **Step 5: Run all tests one final time**

```bash
uvx cram test/statusline/
```

Expected: all PASS

- [ ] **Step 6: Commit any final adjustments**

```bash
git add home/dot_claude/statusline-command.sh
git commit -m "Mark statusline script executable and verify chezmoi deployment"
```

---

## Self-Review Checklist

- [x] **Spec coverage:** Every section of the spec has a corresponding task:
  - Layout/segments → Tasks 2, 3, 7
  - Path shortening → Task 3
  - Rate limits + pace → Task 4
  - Color system → Task 1
  - Session name → Task 5
  - Degradation → Task 6
  - File location → Task 9
  - Testing → all tasks include tests
  - Profiling → Task 8
- [x] **Placeholder scan:** No "TBD", "TODO", or "implement later" — all code is complete
- [x] **Type consistency:** Function names (`shorten_path`, `unique_prefix`, `format_rate_limit`, `render_rate_limit_segment`, `context_color`, `rate_limit_severity`, `worse_rate_limit`, `format_context`, `render_context_segment`, `get_session_name`, `render_name_line`, `visible_width`, `select_degradation_tier`, `colored`) are consistent across tasks
- [x] **Deferred items accounted for:** Task count dropped, 256-color fallback deferred, settings.json management out of scope — all per spec
