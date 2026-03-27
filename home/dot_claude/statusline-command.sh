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

# ── Path shortening (fish-style unique prefix) ─────────────

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
    done < <(ls -1A "$parent" 2>/dev/null)

    # For dot-prefixed names, start at length 2 (the dot alone matches all dot-entries)
    local start_len=1
    [[ "$name" == .* ]] && start_len=2

    # Find shortest prefix that doesn't match any sibling
    local len
    for (( len = start_len; len <= ${#name}; len++ )); do
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
            printf '%s' "$prefix"
            return
        fi
    done

    # Full name if no unique prefix found
    printf '%s' "$name"
}

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
    local under_home=false
    if [[ "$full_path" == "$home"/* ]]; then
        relative="${full_path#"$home"/}"
        under_home=true
    else
        # Outside home — show full absolute path, but still shorten intermediates
        relative="${full_path#/}"
    fi

    # Split into segments
    local IFS='/'
    read -ra segments <<< "$relative"

    local segment_count=${#segments[@]}
    if (( segment_count <= 1 )); then
        if $under_home; then
            echo "$relative"
        else
            echo "/$relative"
        fi
        return
    fi

    # Shorten each intermediate segment (all except last)
    local result=""
    local current_dir
    if $under_home; then
        current_dir="$home"
    else
        current_dir=""
    fi
    local i
    for (( i = 0; i < segment_count - 1; i++ )); do
        local seg="${segments[$i]}"
        if [[ -z "$seg" ]]; then
            continue
        fi
        local parent="$current_dir"
        [[ -z "$parent" ]] && parent="/"
        current_dir="$current_dir/$seg"

        local prefix
        prefix=$(unique_prefix "$seg" "$parent")
        result="${result:+$result/}$prefix"
    done

    # Append full basename
    local output="$result/${segments[$((segment_count - 1))]}"
    if ! $under_home; then
        output="/$output"
    fi
    echo "$output"
}

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
        local projected
        projected=$(echo "scale=2; $pct * $window / $elapsed" | bc)
        local projected_int
        projected_int=$(printf '%.0f' "$projected")
        if (( projected_int > 100 )); then
            over_pace=true
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

# ── Session name ────────────────────────────────────────────

# Extract custom session name from transcript JSONL
# Args: $1 = transcript_path
get_session_name() {
    local transcript="$1"
    [[ -f "$transcript" ]] || return 0

    { grep '"type":"custom-title"' "$transcript" 2>/dev/null || true; } \
        | tail -1 \
        | jq -r '.customTitle // empty' 2>/dev/null
}

# Render the conditional name line (above operational bar)
# Args: $1 = session name (empty = no line)
render_name_line() {
    local name="$1"
    [[ -z "$name" ]] && return 0

    local rows="${LINES:-$(tput lines 2>/dev/null || echo 24)}"
    (( rows < MIN_ROWS_FOR_NAME_LINE )) && return 0

    printf '%s%s %s %s%s %s\n' \
        "$COLOR_NAME_LINE_BG" \
        "$COLOR_DIM_TEXT" "$SYMBOL_SESSION" \
        "$COLOR_BRIGHT_TEXT" "$name" \
        "$COLOR_RESET"
}

# ── Segment rendering ───────────────────────────────────────

# Apply color pair (bg + fg) to text
# Args: $1 = bg escape, $2 = fg escape, $3 = text
colored() {
    printf '%s%s %s %s' "$1" "$2" "$3" "$COLOR_RESET"
}

# Format context percentage text
# Args: $1 = percentage (integer)
format_context() {
    printf 'ctx %d%%\n' "${1:-0}"
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

# ── Degradation ─────────────────────────────────────────────

# Count visible characters (strip ANSI escapes)
# Args: $1 = string
visible_width() {
    printf '%s' "$1" \
        | sed $'s/\033\[[0-9;]*m//g' \
        | sed $'s/\033\[38;2;[0-9;]*m//g' \
        | sed $'s/\033\[48;2;[0-9;]*m//g' \
        | wc -m \
        | tr -d ' '
}

# Select degradation tier based on available width
# Args: $1=cols $2=model $3=path $4=branch $5=rl_worst $6=rl_second $7=context
# Returns: tier number (0-4)
select_degradation_tier() {
    local cols="$1"
    local model="$2" path="$3" branch="$4"
    local rl_worst="$5" rl_second="$6" context="$7"
    local padding=6

    _seg_width() {
        local total=0
        local seg
        for seg in "$@"; do
            [[ -n "$seg" ]] && total=$(( total + ${#seg} + 2 ))
        done
        echo $(( total + padding ))
    }

    # Tier 0: all segments
    local w
    w=$(_seg_width "$model" "$path" "$branch" "$rl_worst" "$rl_second" "$context")
    (( w <= cols )) && { echo 0; return; }

    # Tier 1: drop second rate limit
    w=$(_seg_width "$model" "$path" "$branch" "$rl_worst" "$context")
    (( w <= cols )) && { echo 1; return; }

    # Tier 2: drop path
    w=$(_seg_width "$model" "$branch" "$rl_worst" "$context")
    (( w <= cols )) && { echo 2; return; }

    # Tier 3: drop branch
    w=$(_seg_width "$model" "$rl_worst" "$context")
    (( w <= cols )) && { echo 3; return; }

    # Tier 4: minimum
    echo 4
}

# ── Main (only when not sourced) ────────────────────────────
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    input=$(cat)

    # Terminal width: $COLUMNS if set, else query /dev/tty (works in pipe context),
    # else tput (unreliable in pipes), else fallback
    if [[ -n "${COLUMNS:-}" ]]; then
        cols="$COLUMNS"
    elif stty_out=$(stty size < /dev/tty 2>/dev/null); then
        cols="${stty_out##* }"
    else
        cols=$(tput cols 2>/dev/null || echo 120)
    fi

    # ── Parse JSON (single jq call for efficiency) ──────────
    eval "$(printf '%s' "$input" | jq -r '
        "model=" + (.model.display_name // "Claude" | split(" ") | first | @sh),
        "context_pct=" + (.context_window.used_percentage // 0 | floor | tostring),
        "cwd=" + (.cwd // "" | @sh),
        "transcript=" + (.transcript_path // "" | @sh),
        "wt_name=" + (.worktree.name // "" | @sh),
        "wt_branch=" + (.worktree.branch // "" | @sh),
        "rl_5h_pct=" + (.rate_limits.five_hour.used_percentage // 0 | floor | tostring),
        "rl_5h_resets=" + (.rate_limits.five_hour.resets_at // 0 | floor | tostring),
        "rl_7d_pct=" + (.rate_limits.seven_day.used_percentage // 0 | floor | tostring),
        "rl_7d_resets=" + (.rate_limits.seven_day.resets_at // 0 | floor | tostring)
    ' 2>/dev/null)"

    # ── Compute derived values ──────────────────────────────
    now=$(date +%s)

    # Branch: prefer worktree.branch, fall back to git
    branch=""
    if [[ -n "${wt_branch:-}" ]]; then
        branch="$wt_branch"
    elif [[ -n "${cwd:-}" ]]; then
        branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    fi

    # Path: shortened project path (always if available)
    display_path=""
    if [[ -n "${cwd:-}" ]]; then
        display_path=$(shorten_path "$cwd" "$HOME")
    fi

    # Worktree indicator (shown alongside path when in a worktree)
    worktree_display=""
    if [[ -n "${wt_name:-}" ]]; then
        worktree_display="${SYMBOL_WORKTREE} ${wt_name}"
    fi

    # Rate limit elapsed times (window_duration - time_until_reset)
    rl_5h_elapsed=0
    if (( ${rl_5h_resets:-0} > 0 )); then
        rl_5h_elapsed=$(( 18000 - (rl_5h_resets - now) ))
        (( rl_5h_elapsed < 0 )) && rl_5h_elapsed=0
    fi
    rl_7d_elapsed=0
    if (( ${rl_7d_resets:-0} > 0 )); then
        rl_7d_elapsed=$(( 604800 - (rl_7d_resets - now) ))
        (( rl_7d_elapsed < 0 )) && rl_7d_elapsed=0
    fi

    # Rate limit text (plain, for width measurement and display)
    rl_5h_text=$(format_rate_limit "5h" "${rl_5h_pct:-0}" "$rl_5h_elapsed" 18000)
    rl_7d_text=$(format_rate_limit "7d" "${rl_7d_pct:-0}" "$rl_7d_elapsed" 604800)
    context_text=$(format_context "${context_pct:-0}")

    # ── Smart rate limit ordering ───────────────────────────
    _is_over_pace() {
        local pct="$1" elapsed="$2" window="$3"
        if (( elapsed > 0 && pct >= RATE_LIMIT_SHOW_THRESHOLD )); then
            local projected
            projected=$(echo "scale=2; $pct * $window / $elapsed" | bc)
            local projected_int
            projected_int=$(printf '%.0f' "$projected")
            (( projected_int > 100 )) && { echo true; return; }
        fi
        echo false
    }

    rl_5h_over_pace=$(_is_over_pace "${rl_5h_pct:-0}" "$rl_5h_elapsed" 18000)
    rl_7d_over_pace=$(_is_over_pace "${rl_7d_pct:-0}" "$rl_7d_elapsed" 604800)

    sev_5h=$(rate_limit_severity "${rl_5h_pct:-0}" "$rl_5h_over_pace")
    sev_7d=$(rate_limit_severity "${rl_7d_pct:-0}" "$rl_7d_over_pace")

    worse=$(worse_rate_limit "$sev_5h" "$sev_7d")
    if [[ "$worse" == "first" ]]; then
        rl_worst_text="$rl_5h_text"
        rl_worst_args=("5h" "${rl_5h_pct:-0}" "$rl_5h_elapsed" 18000)
        rl_second_text="$rl_7d_text"
        rl_second_args=("7d" "${rl_7d_pct:-0}" "$rl_7d_elapsed" 604800)
    else
        rl_worst_text="$rl_7d_text"
        rl_worst_args=("7d" "${rl_7d_pct:-0}" "$rl_7d_elapsed" 604800)
        rl_second_text="$rl_5h_text"
        rl_second_args=("5h" "${rl_5h_pct:-0}" "$rl_5h_elapsed" 18000)
    fi

    # ── Degradation ─────────────────────────────────────────
    # Combine path + worktree for width calculation (they drop together)
    location_text="$display_path"
    [[ -n "$worktree_display" ]] && location_text="${location_text}  ${worktree_display}"
    tier=$(select_degradation_tier "$cols" "$model" "$location_text" "$branch" \
        "$rl_worst_text" "$rl_second_text" "$context_text")

    # ── Render segments (left-justified with spacing) ──────
    # Segment separator — 2 spaces for breathing room
    sep="  "

    # Model (always)
    printf '%s%s%s %s %s' "$COLOR_ACCENT_BG" "$COLOR_BOLD" "$COLOR_BRIGHT_TEXT" "$model" "$COLOR_RESET"

    # Path (tier <= 1)
    if (( tier <= 1 )) && [[ -n "$display_path" ]]; then
        printf '%s%s%s%s' "$sep" "$COLOR_PURPLE_TEXT" "$display_path" "$COLOR_RESET"
    fi

    # Worktree indicator (tier <= 1, shown after path)
    if (( tier <= 1 )) && [[ -n "$worktree_display" ]]; then
        printf '%s%s%s%s' "$sep" "$COLOR_CYAN_TEXT" "$worktree_display" "$COLOR_RESET"
    fi

    # Branch (tier <= 2)
    if (( tier <= 2 )) && [[ -n "$branch" ]]; then
        printf '%s%s%s%s' "$sep" "$COLOR_DIM_TEXT" "$branch" "$COLOR_RESET"
    fi

    # Second rate limit (tier 0 only)
    if (( tier <= 0 )) && [[ -n "$rl_second_text" ]]; then
        printf '%s' "$sep"
        render_rate_limit_segment "${rl_second_args[@]}"
    fi

    # Worst rate limit (tier <= 3)
    if (( tier <= 3 )) && [[ -n "$rl_worst_text" ]]; then
        printf '%s' "$sep"
        render_rate_limit_segment "${rl_worst_args[@]}"
    fi

    # Context (always)
    printf '%s' "$sep"
    render_context_segment "${context_pct:-0}"
fi
