#!/usr/bin/env bash
# Cursor CLI status line — theme-aware (Dracula dark / Catppuccin Latte light), adapted from Claude Code statusline
set -euo pipefail

# ── Thresholds ──────────────────────────────────────────────
CONTEXT_WARN_THRESHOLD=50
CONTEXT_CRIT_THRESHOLD=80
MIN_ROWS_FOR_NAME_LINE=15

# ── Agent identity (at-a-glance vs Claude Code) ─────────────
AGENT_LABEL="CU"

# ── Symbols ─────────────────────────────────────────────────
SYMBOL_SESSION="⌘"
SYMBOL_WORKTREE="⊕"

# ── Theme detection ─────────────────────────────────────────

detect_theme() {
    case "${CLITHEME:-auto}" in
        dark|light) echo "$CLITHEME"; return ;;
    esac

    if [[ -e /dev/tty ]]; then
        local response="" old_stty=""
        { exec 3</dev/tty 4>/dev/tty; } 2>/dev/null || { echo dark; return; }
        old_stty=$(stty -g <&3 2>/dev/null) || old_stty=""
        [[ -n "$old_stty" ]] && stty -echo raw <&3 2>/dev/null
        printf '\e]11;?\e\\' >&4 2>/dev/null
        if IFS= read -r -d $'\\' -t 1 response <&3 2>/dev/null; then
            if [[ "$response" =~ rgb:([0-9a-fA-F]{2,4})/([0-9a-fA-F]{2,4})/([0-9a-fA-F]{2,4}) ]]; then
                local r="${BASH_REMATCH[1]:0:2}" g="${BASH_REMATCH[2]:0:2}" b="${BASH_REMATCH[3]:0:2}"
                local ri=$((16#$r)) gi=$((16#$g)) bi=$((16#$b))
                local lum=$(( (ri * 299 + gi * 587 + bi * 114) / 1000 ))
                [[ -n "$old_stty" ]] && stty "$old_stty" <&3 2>/dev/null
                { exec 3<&- 4>&-; } 2>/dev/null
                if (( lum > 128 )); then
                    echo light
                else
                    echo dark
                fi
                return
            fi
        fi
        [[ -n "$old_stty" ]] && stty "$old_stty" <&3 2>/dev/null
        { exec 3<&- 4>&-; } 2>/dev/null
    fi

    echo dark
}

# ── Colors (ANSI 24-bit truecolor) ─────────────────────────

COLOR_BOLD=$'\033[1m'
COLOR_RESET=$'\033[0m'

init_palette() {
    local theme="${1:-dark}"
    case "$theme" in
        light)
            # Catppuccin Latte
            COLOR_SUBTLE_GREEN_BG=$'\033[48;2;223;239;221m' # #dfefdd
            COLOR_YELLOW_BG=$'\033[48;2;223;142;29m'        # #df8e1d
            COLOR_RED_BG=$'\033[48;2;210;15;57m'            # #d20f39
            COLOR_ACCENT_BG=$'\033[48;2;114;135;172m'       # #7287ac — muted blue (Cursor)
            COLOR_NAME_LINE_BG=$'\033[48;2;204;208;218m'    # #ccd0da — surface0

            COLOR_DARK_TEXT=$'\033[38;2;239;241;245m'       # #eff1f5 — base (pill text)
            COLOR_BRIGHT_TEXT=$'\033[38;2;76;79;105m'       # #4c4f69 — text
            COLOR_DIM_TEXT=$'\033[38;2;156;160;176m'        # #9ca0b0 — overlay0
            COLOR_PURPLE_TEXT=$'\033[38;2;136;57;239m'      # #8839ef — mauve
            COLOR_CYAN_TEXT=$'\033[38;2;23;146;153m'        # #179299 — teal
            COLOR_GREEN_TEXT=$'\033[38;2;64;160;43m'        # #40a02b — green
            ;;
        *)
            # Dracula (default)
            COLOR_SUBTLE_GREEN_BG=$'\033[48;2;34;51;34m'   # #223322
            COLOR_YELLOW_BG=$'\033[48;2;241;250;140m'      # #f1fa8c
            COLOR_RED_BG=$'\033[48;2;255;85;85m'           # #ff5555
            COLOR_ACCENT_BG=$'\033[48;2;30;58;95m'         # #1e3a5f — muted navy (Cursor)
            COLOR_NAME_LINE_BG=$'\033[48;2;40;42;54m'      # #282a36 — background

            COLOR_DARK_TEXT=$'\033[38;2;40;42;54m'         # #282a36 — background (pill text)
            COLOR_BRIGHT_TEXT=$'\033[38;2;248;248;242m'    # #f8f8f2 — foreground
            COLOR_DIM_TEXT=$'\033[38;2;98;114;164m'        # #6272a4 — comment
            COLOR_PURPLE_TEXT=$'\033[38;2;189;147;249m'    # #bd93f9 — purple
            COLOR_CYAN_TEXT=$'\033[38;2;139;233;253m'      # #8be9fd — cyan
            COLOR_GREEN_TEXT=$'\033[38;2;80;250;123m'      # #50fa7b — green
            ;;
    esac
}

init_palette dark

# ── Path shortening (fish-style unique prefix) ─────────────

unique_prefix() {
    local name="$1"
    local parent="$2"
    local siblings=()
    local entry
    while IFS= read -r entry; do
        [[ "$entry" != "$name" ]] && siblings+=("$entry")
    done < <(ls -1A "$parent" 2>/dev/null)

    local start_len=1
    [[ "$name" == .* ]] && start_len=2

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
    printf '%s' "$name"
}

shorten_path() {
    local full_path="$1"
    local home="${2:-$HOME}"

    if [[ "$full_path" == "$home" ]]; then
        echo "~"
        return
    fi

    local relative=""
    local under_home=false
    if [[ "$full_path" == "$home"/* ]]; then
        relative="${full_path#"$home"/}"
        under_home=true
    else
        relative="${full_path#/}"
    fi

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
        [[ -z "$seg" ]] && continue
        local parent="$current_dir"
        [[ -z "$parent" ]] && parent="/"
        current_dir="$current_dir/$seg"
        local prefix
        prefix=$(unique_prefix "$seg" "$parent")
        result="${result:+$result/}$prefix"
    done

    local output="$result/${segments[$((segment_count - 1))]}"
    if ! $under_home; then
        output="/$output"
    fi
    echo "$output"
}

# ── Segment rendering ───────────────────────────────────────

colored() {
    printf '%s%s %s %s' "$1" "$2" "$3" "$COLOR_RESET"
}

format_context() {
    printf 'ctx %d%%\n' "${1:-0}"
}

render_context_segment() {
    local pct="${1:-0}"
    local text
    text=$(format_context "$pct")
    if (( pct >= CONTEXT_CRIT_THRESHOLD )); then
        colored "$COLOR_RED_BG" "$COLOR_DARK_TEXT" "$text"
    elif (( pct >= CONTEXT_WARN_THRESHOLD )); then
        colored "$COLOR_YELLOW_BG" "$COLOR_DARK_TEXT" "$text"
    else
        colored "$COLOR_SUBTLE_GREEN_BG" "$COLOR_GREEN_TEXT" "$text"
    fi
}

# ── Degradation ─────────────────────────────────────────────

visible_width() {
    printf '%s' "$1" \
        | sed $'s/\033\[[0-9;]*m//g' \
        | sed $'s/\033\[38;2;[0-9;]*m//g' \
        | sed $'s/\033\[48;2;[0-9;]*m//g' \
        | wc -m \
        | tr -d ' '
}

# Args: $1=cols $2=model $3=path $4=branch $5=context
# Returns: tier number (0-3)
select_degradation_tier() {
    local cols="$1"
    local model="$2" path="$3" branch="$4" context="$5"
    local padding=6

    _seg_width() {
        local total=0
        local seg
        for seg in "$@"; do
            [[ -n "$seg" ]] && total=$(( total + ${#seg} + 2 ))
        done
        echo $(( total + padding ))
    }

    local w
    w=$(_seg_width "$model" "$path" "$branch" "$context")
    (( w <= cols )) && { echo 0; return; }

    w=$(_seg_width "$model" "$branch" "$context")
    (( w <= cols )) && { echo 1; return; }

    w=$(_seg_width "$model" "$context")
    (( w <= cols )) && { echo 2; return; }

    echo 3
}

# ── Name line ───────────────────────────────────────────────

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

# ── Main (only when not sourced) ────────────────────────────
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    input=$(cat)

    init_palette "$(detect_theme)"

    if [[ -n "${COLUMNS:-}" ]]; then
        cols="$COLUMNS"
    elif stty_out=$(stty size < /dev/tty 2>/dev/null); then
        cols="${stty_out##* }"
    else
        cols=$(tput cols 2>/dev/null || echo 120)
    fi

    eval "$(printf '%s' "$input" | jq -r '
        "model=" + (.model.display_name // "Cursor" | split(" ") | first | @sh),
        "context_pct=" + (.context_window.used_percentage // 0 | floor | tostring),
        "cwd=" + (.cwd // "" | @sh),
        "session_name=" + (.session_name // "" | @sh),
        "wt_name=" + (.worktree.name // "" | @sh)
    ' 2>/dev/null)"

    # Branch: always from git (Cursor payload has no worktree.branch)
    branch=""
    if [[ -n "${cwd:-}" ]]; then
        branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    fi

    display_path=""
    if [[ -n "${cwd:-}" ]]; then
        display_path=$(shorten_path "$cwd" "$HOME")
    fi

    worktree_display=""
    if [[ -n "${wt_name:-}" ]]; then
        worktree_display="${SYMBOL_WORKTREE} ${wt_name}"
    fi

    # Combine path + worktree for degradation width measurement
    location_text="$display_path"
    [[ -n "$worktree_display" ]] && location_text="${location_text}  ${worktree_display}"

    model_display="${AGENT_LABEL}·${model}"

    context_text=$(format_context "${context_pct:-0}")
    tier=$(select_degradation_tier "$cols" "$model_display" "$location_text" "$branch" "$context_text")

    render_name_line "${session_name:-}"

    sep="  "

    # Model (always)
    printf '%s%s%s %s %s' "$COLOR_ACCENT_BG" "$COLOR_BOLD" "$COLOR_BRIGHT_TEXT" "$model_display" "$COLOR_RESET"

    # Path (tier 0)
    if (( tier <= 0 )) && [[ -n "$display_path" ]]; then
        printf '%s%s%s%s' "$sep" "$COLOR_PURPLE_TEXT" "$display_path" "$COLOR_RESET"
    fi

    # Worktree indicator (tier 0, shown after path)
    if (( tier <= 0 )) && [[ -n "$worktree_display" ]]; then
        printf '%s%s%s%s' "$sep" "$COLOR_CYAN_TEXT" "$worktree_display" "$COLOR_RESET"
    fi

    # Branch (tier <= 1)
    if (( tier <= 1 )) && [[ -n "$branch" ]]; then
        printf '%s%s%s%s' "$sep" "$COLOR_DIM_TEXT" "$branch" "$COLOR_RESET"
    fi

    # Context (always)
    printf '%s' "$sep"
    render_context_segment "${context_pct:-0}"
fi
