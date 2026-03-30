#!/bin/sh

set -eu

CHEZMOI_DIFF_EXCLUDE_REGEX="^$HOME/\\.claude/settings\\.json$"

check_clean_chezmoi_diff() {
    diff_output_path=$1
    managed_paths=$(mktemp)
    trap 'rm -f "$managed_paths"' EXIT INT TERM

    chezmoi managed --include=files --path-style=absolute --nul-path-separator |
        tr '\0' '\n' |
        grep -Ev "$CHEZMOI_DIFF_EXCLUDE_REGEX" |
        tr '\n' '\0' >"$managed_paths"

    if [ -s "$managed_paths" ]; then
        xargs -0 chezmoi diff --no-pager --include=files <"$managed_paths" >"$diff_output_path"
    else
        : >"$diff_output_path"
    fi

    test ! -s "$diff_output_path"
}
